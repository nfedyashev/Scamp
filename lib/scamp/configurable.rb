class Scamp
  class << self
    attr_accessor :subdomain
    attr_accessor :api_key
    attr_accessor :first_match_only

    attr_accessor :verbose
    attr_accessor :logger
  end

  module Configurable
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
      def configure(options)
        raise ArgumentError, "You must pass an API key" unless options[:api_key]
        raise ArgumentError, "You must pass a subdomain" unless options[:subdomain]

        logger       = Logger.new(STDOUT)
        logger.level = Logger::DEBUG

        self.class.api_key          = options[:api_key]
        self.class.subdomain        = options[:subdomain]
        self.class.first_match_only = !!options[:first_match_only]

        self.class.verbose          = !!options[:verbose]
        self.class.logger           = logger

        options.each do |k,v|
          s = "#{k}="
          if respond_to?(s)
            send(s, v)
          else
            logger.warn "Scamp initialized with #{k.inspect} => #{v.inspect} but NO UNDERSTAND!"
          end
        end
      end
    end
    module ClassMethods
    end
  end
end
