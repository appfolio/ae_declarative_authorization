require 'blockenspiel'
require 'active_support/concern'

module DeclarativeAuthorization
  module Test
    module Helpers
      extend ActiveSupport::Concern

      class InvalidParamsBlockArity < StandardError
        def initialize(params_block_name, params_block_arity, max_arity)
          message = "Params block '#{params_block_name}' has arity of #{params_block_arity}. Max params block arity is #{max_arity}."
          super(message)
        end
      end

      class PrivilegeTestGenerator
        include Blockenspiel::DSL

        def initialize(test_class, role, privileges)
          @test_class = test_class
          @role = role
          @privileges = [privileges].flatten
        end

        def allowed(options)
          return unless @test_class.run_assertion?(options)

          role, privileges, actions, params_name = extract_options(options)

          actions.each do |action|
            privileges.each do |privilege|
              @test_class.send(:define_method, "test_#{action}__access_allowed__#{role}_role__#{privilege ? "#{privilege}_permissions__" : ""}with_#{params_name || 'no_params'}") do
                priv_param = (privilege == :hidden ? nil : privilege)
                if forbidden_with_role_and_privilege?(action, role, priv_param, params_name, options)
                  flunk "The '#{action}' action #{params_name ? "with '#{params_name}' parameters " : ''}should be accessible for users with #{privilege ? "'#{privilege}' permissions for " : ""}the '#{role}' role."
                end
              end
            end
          end
        end

        def denied(options)
          return unless @test_class.run_assertion?(options)

          role, privileges, actions, params_name = extract_options(options)

          actions.each do |action|
            privileges.each do |privilege|
              @test_class.send(:define_method, "test_#{action}__access_denied__#{role}_role__#{privilege ? "#{privilege}_permissions__" : ""}with_#{params_name || 'no_params'}") do
                priv_param = (privilege == :hidden ? nil : privilege)
                unless forbidden_with_role_and_privilege?(action, role, priv_param, params_name, options)
                  flunk "The '#{action}' action #{params_name ? "with '#{params_name}' parameters " : ''}should NOT be accessible for users with #{privilege ? "'#{privilege}' permissions for " : ""}the '#{role}' role."
                end
              end
            end
          end
        end

        protected

        def extract_options(options)
          # Can't use these instance variable from inside a method on the test class
          role        = @role
          privileges   = @privileges

          actions     = options[:to]
          raise ':to is a required option!' unless actions

          actions     = [actions] unless actions.is_a?(Array)
          params_name      = options[:with]

          [role, privileges, actions, params_name]
        end

      end

      class RoleTestGenerator
        include Blockenspiel::DSL

        def initialize(test_class, role)
          @test_class = test_class
          @role = role
        end

        def privilege(privilege, &block)
          privileges = [privilege].flatten.uniq

          unless privileges.all? { |privilege| [:granted, :hidden, :read, :write, :write_without_delete].include?(privilege) }
            raise "Privilege (:when) must be :granted, :hidden, :read, :write_without_delete, or :write. Found #{privilege.inspect}."
          end

          Blockenspiel.invoke(block, PrivilegeTestGenerator.new(@test_class, @role, privileges))
        end

        def allowed(options)
          return unless @test_class.run_assertion?(options)

          if options[:when]
            privilege(options[:when]) { allowed(options) }
          else
            Blockenspiel.invoke(Proc.new {allowed(options)}, PrivilegeTestGenerator.new(@test_class, @role, nil))
          end
        end

        def denied(options)
          return unless @test_class.run_assertion?(options)

          if options[:when]
            privilege(options[:when]) { denied(options) }
          else
            Blockenspiel.invoke(Proc.new {denied(options)}, PrivilegeTestGenerator.new(@test_class, @role, nil))
          end
        end

      end

      class AccessTestGenerator
        include Blockenspiel::DSL

        def initialize(test_class)
          @test_class = test_class
        end

        def params(name, &block)
          @test_class.define_access_test_params_method(name, &block)
        end

        def role(role, &block)
          raise "Role cannot be blank!" if role.blank?

          Blockenspiel.invoke(block, RoleTestGenerator.new(@test_class, role)) if @test_class.run_role_test?(role)
        end
      end

      class AccessTestParser
        include Blockenspiel::DSL

        def initialize(test_class)
          @test_class = test_class
        end

        def params(_name, &_block);end

        def role(role, &block)
          Blockenspiel.invoke(block, self) if @test_class.run_role_test?(role)
        end

        def privilege(_privilege, &block)
          Blockenspiel.invoke(block, self)
        end

        def allowed(options)
          if options[:only]
            @test_class.run_all_assertions = false
          end
        end

        def denied(options)
          if options[:only]
            @test_class.run_all_assertions = false
          end
        end
      end

      module ClassMethods
        attr_reader :access_tests_defined, :only_run_roles
        attr_accessor :run_all_assertions

        def skip_access_tests_for_actions(*actions)
          @skipped_access_test_actions ||= []
          @skipped_access_test_actions += actions.map(&:to_sym)
        end

        def access_tests(only_run_roles: nil, &block)
          @access_tests_defined = true
          @run_all_assertions = true
          @only_run_roles = only_run_roles
          file_output ||= [ Dir.tmpdir + '/test/profiles/access_checking', ENV['TEST_ENV_NUMBER'] ].compact.join('.')
          unless File.exist?(file_output)
            FileUtils.mkdir_p(File.dirname(file_output))
          end
          File.open(file_output, "a+") do |file|
            file.puts self.controller_class.name
          end

          Blockenspiel.invoke(block, AccessTestParser.new(self))
          Blockenspiel.invoke(block, AccessTestGenerator.new(self))
        end

        def this_is_an_abstract_controller_so_it_needs_no_access_tests
          undef_method :test_access_tests_defined if self.method_defined? :test_access_tests_defined
          undef_method :test_all_public_actions_covered_by_role_tests if self.method_defined? :test_all_public_actions_covered_by_role_tests
        end

        alias :this_is_a_module_mixed_into_controllers_so_it_needs_no_access_tests :this_is_an_abstract_controller_so_it_needs_no_access_tests
        alias :the_access_tests_are_tested_elsewhere_so_no_access_tests_are_needed :this_is_an_abstract_controller_so_it_needs_no_access_tests
        alias :access_tests_not_required :this_is_an_abstract_controller_so_it_needs_no_access_tests

        def all_public_actions
          actions = []
          if defined?(Grape) && [Grape::API, Grape::API::Instance].any? { |base| controller_class < base }
            actions += controller_class.routes.map { |api| "#{api.request_method} #{api.origin}" }
          else
            actions += controller_class.public_instance_methods(false)
            actions += controller_class.superclass.public_instance_methods(false)
          end

          actions.reject! do |method|
            method =~ /^_/ ||
              method =~ /^rescue_action/ ||
              (@skipped_access_test_actions.is_a?(Array) && @skipped_access_test_actions.include?(method))
          end

          actions.uniq
        end

        def inherited(child)
          super

          child.send(:define_method, :test_access_tests_defined) do
            assert self.class.access_tests_defined, 'Access tests needed but not defined.'
          end

          child.send(:define_method, :test_all_public_actions_covered_by_role_tests) do
            test_methods = self.public_methods(false).select { |method| method =~ /^test_/ }
            untested_actions = self.class.all_public_actions.select { |action| !test_methods.any? { |method| method =~ /^test_#{action}__access_/} }
            unless untested_actions.empty?
              flunk "In #{self.class.name}, it appears that #{untested_actions.map(&:inspect).to_sentence} are not tested by any access_tests. Did you forget them?"
            end
          end
        end

        def define_access_test_params_method(name, &block)
          define_method("access_test_params_for_#{name}", &block)
        end

        def run_role_test?(role)
          @only_run_roles.nil? || @only_run_roles.include?(role)
        end

        def run_assertion?(assertion_options)
          @run_all_assertions || assertion_options[:only]
        end

      end

      protected

      def response_forbidden?
        flash[:error] == 'You do not have the correct permissions to access that page. Click the back button to return to your previous page.' ||
        flash[:error] =~ /You do not have the correct permissions to view this/ ||
        flash[:error] =~ /You do not have access to/ ||
        flash[:alert] =~ /You need to sign in/ ||
        (@response.location =~ /\/users\/sign_in/ && @response.code == "302")
      end

      def access_test_params_for_param_methods
        []
      end

      def access_test_params(name)
        return { } unless name.present?

        params    = access_test_params_for_param_methods
        max_arity = params.size

        full_method_name = "access_test_params_for_#{name}"
        method_arity = method(full_method_name).arity

        unless method_arity <= max_arity
          raise InvalidParamsBlockArity.new(name, method_arity, max_arity)
        end

        send(full_method_name, *params[0...method_arity])
      end

      def access_test_user(role, privilege)
        raise 'MUST IMPLEMENT!!!'
      end

      def forbidden_with_role_and_privilege?(action, role, privilege, params_name = nil, options = {})
        http_method = options[:method] || :get
        xhr = options[:xhr]

        user = access_test_user(role, privilege)
        params = access_test_params(params_name)

        send_args = [http_method, action.to_sym]
        send_kwargs = { params: params }
        send_kwargs[:xhr] = true if xhr

        errors_to_reraise = [
          ActionController::RoutingError,
          ActionController::UrlGenerationError,
          AbstractController::ActionNotFound
        ]

        errors_to_reraise << Mocha::ExpectationError if defined?(Mocha::ExpectationError)

        begin
          send *send_args, **send_kwargs
          return response_forbidden?
        rescue *errors_to_reraise => e
          raise e
        rescue => e
          if options[:print_error]
            puts "\n#{e.class.name} raised in action '#{action}':"
            puts e.message
            puts e.backtrace.join("\n")
          end
          return false
        end
      end

    end
  end
end
