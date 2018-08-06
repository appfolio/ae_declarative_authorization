module PraxisDummy
  module Models
    class MockModel
      def initialize(attrs = {})
        attrs.each do |key, value|
          instance_variable_set(:"@#{key}", value)
          self.class.class_eval do
            attr_reader key
          end
        end
      end

      def self.descends_from_active_record?
        true
      end

      def self.table_name
        name.tableize
      end

      def self.name
        "MockModel"
      end

      def self.find(*args)
        raise StandardError, "Couldn't find #{self.name} with id #{args[0].inspect}" unless args[0]
        new :id => args[0]
      end

      def self.find_or_initialize_by(args)
        raise StandardError, "Syntax error: find_or_initialize by expects a hash: User.find_or_initialize_by(:id => @user.id)" unless args.is_a?(Hash)
        new args
      end

      def ==(other)
        self.id == other.id
      end
    end
  end
end
