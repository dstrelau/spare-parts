module UnmodifiableAttribute
  
  module InstanceMethods
    def unmodifiable_attr(*attr_names)
      attr_names.each do |name|
        self.instance_eval do
          define_method("protected_#{name.to_s}=") do |value|
            if send(name).nil?
              send("original_#{name.to_s}=", value)
            else
              raise ActiveRecord::UnmodifiableAttributeError.new(name)
            end
          end
          
          alias_method "original_#{name.to_s}=",  "#{name.to_s}="
          alias_method "#{name.to_s}=",           "protected_#{name.to_s}="
        end
      end
    end
  end
  
  module Errors
    class UnmodifiableAttributeError < ActiveRecord::ActiveRecordError
      attr_reader :attribute
      def initialize(attribute)
        @attribute = attribute
        super("Attribute #{attribute} cannot be modified.")
      end
    end
  end
  
end


ActiveRecord::Base.send :extend, UnmodifiableAttribute::InstanceMethods
ActiveRecord.send :include, UnmodifiableAttribute::Errors
