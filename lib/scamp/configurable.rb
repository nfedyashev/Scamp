class Scamp
  cattr_accessor :subdomain
  cattr_accessor :api_key
  cattr_accessor :first_match_only

  cattr_accessor :verbose
  cattr_accessor :logger

  module Configurable
    def self.included(base)
      base.send :include, InstanceMethods
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
  end
end
