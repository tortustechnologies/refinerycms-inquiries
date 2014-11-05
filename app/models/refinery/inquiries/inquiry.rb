require 'refinery/core/base_model'
require 'filters_spam'

module Refinery
  module Inquiries
    class Inquiry < Refinery::Core::BaseModel

      filters_spam :message_field => :message,
                   :email_field => :email,
                   :author_field => :name,
                   :other_fields => [:phone],
                   :extra_spam_words => Refinery::Inquiries.extra_spam_words

      validates :name, :presence => true
      validates :email, :format => { :with =>  /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
      validates :message, :presence => true

      default_scope :order => 'created_at DESC'

      attr_accessible :name, :phone, :message, :email

      def self.latest(number = 7, include_spam = false)
        include_spam ? limit(number) : ham.limit(number)
      end

      def self.custom_attribute_names
        Inquiries.custom_inquiry_attributes.keys
      end

      if Inquiries.custom_inquiry_attributes.any?
        store :custom_store, :accessors => custom_attribute_names

        Inquiries.custom_inquiry_attributes.each do |attribute_name, config|
          attr_accessible attribute_name

          if config[:required] || (config[:validates] && config[:validates][:presence])
            config[:required] = true unless custom_attribute_configs.has_key?(:required)
            config[:label] ||= attribute_name.to_s.titleize + ' *'
          else
            config[:label] ||= attribute_name.to_s.titleize
          end

          if config[:validates].kind_of?(Hash)
            validates attribute_name, config[:validates]
          end
        end
      end

      if (attrs_with_defaults = custom_attribute_configs.select {|key, config| config[:default].present? }) && attrs_with_defaults.any?
        define_method(:init_custom_attributes) do
          attrs_with_defaults.each do |attribute, config|
            self.send("#{attribute}=", config[:default])
          end
        end
        after_initialize :init_custom_attributes
      end

      # Returns names and values of all custom attributes
      # as a hash in the format: {:attr1 => value, :attr2 => value, ...}
      def custom_attributes
        self.class.custom_attribute_names.inject({}) do |values, name|
          values[name.to_sym] = self.send(name)
          values
        end
      end

    end
  end
end
