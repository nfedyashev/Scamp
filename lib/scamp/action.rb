#
# Actions are run in the context of a Scamp::Action.
# This allows us to make room, user etc. methods
# available on a per-message basis
#

# {:room_id=>401839, :created_at=>"2011/09/10 00:23:19 +0000", :body=>"something", :id=>408089344, :user_id=>774016, :type=>"TextMessage"}

class Scamp
  class Action

    attr_accessor :matches

    def initialize(action, message)
      @action  = action
      @message = message
    end

    def matches=(match)
      @matches = match[1..-1]
      match.names.each do |name|
        name_s = name.to_sym
        self.class.send :define_method, name_s do
          match[name_s]
        end
      end if match.respond_to?(:names) # 1.8 doesn't support named captures
    end

    def room_id
      @message.room.id
    end

    #FIXME - must be room_name to keep it consisten
    def room
      @message.room.name
    end

    def user
      @message.user.name
    end

    #FIXME - must be room_name to keep it consisten
    def user_id
      @message.user.id
    end

    def message
      @message.body
    end

    def run
      self.instance_eval &@action
    end

    #def command_list
    #  bot.command_list
    #end

    #def say(msg, room_id_or_name = room_id)
    def say(msg, _ = {})
      ::Scamp::API.say(msg, @message.room)
    end

    #def paste(msg, room_id_or_name = room_id)
    def paste(msg, _ = {})
      ::Scamp::API.paste(msg, @message.room)
    end

    #def play(sound, room_id_or_name = room_id)
    def play(sound, _ = {})
      ::Scamp::API.play(sound, @message.room)
    end
  end
end
