class Scamp
  class Expectation
    attr_accessor :value, :ignore_self, :conditions, :trigger, :action, :matches, :required_prefix
    
    #def initialize(message, params = {})
    def initialize(value, params = {})
      send("value=", value)

      params ||= {}
      params[:conditions] ||= {}
      params.each do |k,v|
        puts("#{k}=", v)
        send("#{k}=", v)
      end
      #@bot = bot
    end

    #def check(expectation)
    def check(message)
      if matches?(message)
        action_run = Action.new(action, message)
        action_run.matches = matches unless matches.nil?
        action_run.run
      end
    end

    #def matches?(expectation)
    def matches?(message)
      return false if ignore_self_message?(message)

      conditions_match?(message) && message_body_match?(message)
    end

    #def attempt(msg)
    #  return false unless conditions_satisfied_by(msg)
    #  match = triggered_by(msg[:body])
    #  if match
    #    if match.is_a? MatchData
    #      run(msg, match)
    #    else
    #      run(msg)
    #    end
    #    return true
    #  end
    #  false
    #end

    private

    def ignore_self_message?(message)
      ignore_self && message.user == UserRepository.get('me')
    end

    def conditions_match?(message)
                     #=> [:room, 123]
      conditions.all? do |item, cond|
        puts "Checking #{item} against #{cond}"
        #bot.logger.debug "msg is #{msg.inspect}"
        case item
        when :room, :rooms
          if cond.is_a? Array
            cond.collect{ |c| RoomRepository.get(c) }.include?(message.room)
          else
            message.room == RoomRepository.get(cond)
          end
        when :user, :users
          if cond.is_a? Array
            cond.collect{ |c| UserRepository.get(c) }.include?(message.user)
          else
            message.user == UserRepository.get(cond)
          end
        end
      end
    end
    
    #def message_body_match?(expectation)
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
    
    #def triggered_by(message_text)
    #  if message_text && required_prefix 
    #    message_text = handle_prefix(message_text)
    #    return false unless message_text
    #  end
    #  if trigger.is_a? String
    #    return true if trigger == message_text
    #  elsif trigger.is_a? Regexp
    #    return trigger.match message_text
    #  else
    #    #bot.logger.warn "Don't know what to do with #{trigger.inspect} at #{__FILE__}:#{__LINE__}"
    #  end
    #  false
    #end
    
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

    #def run(msg, match = nil)
    #  action_run = Action.new(action, msg)
    #  action_run.matches = match if match
    #  action_run.run
    #end

    #def conditions_satisfied_by(msg)
    #  #bot.logger.debug "Checking message against #{conditions.inspect}"
    #  
    #  # item will be :user or :room
    #  # cond is the int or string value.
    #  conditions.each do |item, cond|
    #    #bot.logger.debug "Checking #{item} against #{cond}"
    #    #bot.logger.debug "msg is #{msg.inspect}"
    #    if cond.is_a? Integer
    #      # bot.logger.debug "item is #{msg[{:room => :room_id, :user => :user_id}[item]]}"
    #      return false unless msg[{:room => :room_id, :user => :user_id}[item]] == cond
    #    elsif cond.is_a? String
    #      case item
    #      when :room
    #        return false unless bot.room_name_for(msg[:room_id]) == cond
    #      when :user
    #        return false unless bot.username_for(msg[:user_id]) == cond
    #      end
    #      #bot.logger.error "Don't know how to deal with a match item of #{item}, cond #{cond}"
    #    elsif cond.is_a? Array
    #      case item
    #      when :room, :rooms
    #        return cond.select {|e| e.is_a? Integer }.include?(msg[{:room => :room_id}[item]]) ||
    #               cond.select {|e| e.is_a? String }.include?(bot.room_name_for(msg[:room_id]))
    #      end
    #      #bot.logger.error "Don't know how to deal with a match item of #{item}, cond #{cond}"
    #    end
    #  end
    #  true
    #end
  end
end
