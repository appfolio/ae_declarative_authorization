# frozen_string_literal: true

#
# Observability support for declarative authorization
#
module Authorization
  module Controller
    module Observability
      def trace_authorization(*args, &block)
        if ::Authorization.config.trace_authorization
          ::Authorization.config.trace_authorization.call(*args, &block)
        else
          yield
        end
      end
    end
  end
end
