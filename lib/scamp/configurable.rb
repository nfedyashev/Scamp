class Scamp
  cattr_accessor :subdomain
  cattr_accessor :api_key
  cattr_accessor :first_match_only
  cattr_accessor :required_prefix

  cattr_accessor :tinder_campfire
  cattr_accessor :verbose

  module Configurable
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
    end

    module InstanceMethods
      def configure(options)
        raise ArgumentError, "You must pass an API key"  unless options[:api_key]
        raise ArgumentError, "You must pass a subdomain" unless options[:subdomain]

        self.class.api_key          = options[:api_key]
        self.class.subdomain        = options[:subdomain]
        self.class.first_match_only = !!options[:first_match_only]

        self.class.verbose          = !!options[:verbose]

        options.each do |k,v|
          s = "#{k}="
          if respond_to?(s)
            send(s, v)
          else
            logger.warn "Scamp initialized with #{k.inspect} => #{v.inspect} but NO UNDERSTAND!"
          end
        end
      end

      def logger
        ::Scamp.logger
      end
    end

    module ClassMethods
      def logger
        if @logger.blank?
          logger = Logger.new(ENV['SCAMP_LOGGING'] ? STDOUT : nil)
          logger.level = Logger::DEBUG
          @logger = logger
        end
        @logger
      end

      def logger=(logger)
        @logger = ::Tinder.logger = logger
      end
    end
  end
end
