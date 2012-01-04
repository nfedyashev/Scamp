#
# Actions are run in the context of a Scamp::Action.
# This allows us to make room, user etc. methods
# available on a per-message basis
#
class Scamp
  class Action
    attr_accessor :matches

    def initialize(action, message)
      raise "missing lambda action" unless action.class  == Proc
      raise "invalid message type"  unless message.class == Message

      @action  = action
      @message = message
    end

    def user
      @message.user.name
    end

    def room
      @message.room.name
    end

    def say(msg, room_in_loose_format = nil)
      r = post_to_room(room_in_loose_format)
      if r.present?
        r.say(msg)
      else
        ::Scamp.logger.warn "Can't post to room #{room_in_loose_format}"
      end
    end

    def play(sound, room_in_loose_format = nil)
      r = post_to_room(room_in_loose_format)
      if r.present?
        r.play(sound)
      else
        ::Scamp.logger.warn "Can't post to room #{room_in_loose_format}"
      end
    end

    def room_id
      @message.room.id
    end

    def user_id
      @message.user.id
    end

    def message
      @message.body
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

    def run
      self.instance_eval &@action
    end

    #def command_list
    #  bot.command_list
    #end

    private

    def post_to_room(room_in_loose_format)
      if room_in_loose_format.present?
        if tinder_room = Room.get_tinder_room_by_id_or_name(room_in_loose_format)
          ::Repository[Room].search(tinder_room.id).first
        end
      else
        @message.room
      end
    end
  end
end
