class Scamp
  class Expectation
    attr_accessor :value, :ignore_self, :conditions, :trigger, :action, :matches, :required_prefix

    def initialize(value, params = {})
      send("value=", value)

      params ||= {}
      params[:conditions] ||= {}
      params.each do |k,v|
        puts("#{k}=", v)
        send("#{k}=", v)
      end
    end

    def check(message)
      if matches?(message)
        action_run = Action.new(action, message)
        action_run.matches = matches unless matches.nil?
        action_run.run
      end
    end

    def matches?(message)
      return false if ignore_self_message?(message)

      conditions_match?(message) && message_body_match?(message)
    end

    private

    def ignore_self_message?(message)
      ignore_self && message.user == UserRepository.get('me')
    end

    def conditions_match?(message)
      conditions.all? do |key, expectation|
        puts "Checking #{key} against #{expectation}"
        #bot.logger.debug "msg is #{msg.inspect}"
        case key 
        when :room, :rooms
          if expectation.is_a? Array
            expectation.collect{ |c| RoomRepository.get(c) }.include?(message.room)
          else
            message.room == RoomRepository.get(expectation)
          end
        when :user, :users
          if expectation.is_a? Array
            expectation.collect{ |c| UserRepository.get(c) }.include?(message.user)
          else
            message.user == UserRepository.get(expectation)
          end
        end
      end
    end

    def message_body_match?(message)
      if message && required_prefix 
        #FIXME - remove side effect
        message.body = handle_prefix(message)
        return false unless message.body
      end
      if value.is_a? String
        return true if message.body == value
      elsif value.is_a? Regexp
        #FIXME - remove side effect
        return self.matches = message.body.match(value)
      else
        #bot.logger.warn "Don't know what to do with #{trigger.inspect} at #{__FILE__}:#{__LINE__}"
      end
      false
    end

    def handle_prefix(message)
      return false unless value

      if required_prefix.is_a? String
        if required_prefix == message.body[0...required_prefix.length]
          value.gsub(required_prefix, '') 
        else
          false
        end
      elsif required_prefix.is_a? Regexp
        if required_prefix.match message.body
          message.body.gsub(required_prefix, '')
        else
          false
        end
      else
        false
      end
    end
  end
end
