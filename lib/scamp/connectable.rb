# encoding: UTF-8
class Scamp
  module Connectable
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def connect!(room_in_loose_format, &blk)
        logger.info "Starting up…"

        ::Scamp.tinder_campfire = ::Tinder::Campfire.new(::Scamp.subdomain, :token => ::Scamp.api_key)

        sign_in 

        room = prepared_tinder_room(room_in_loose_format)
        room.listen &process_message
      end

      private

      def sign_in
        user = User.make(::Scamp.tinder_campfire.me)
        Repository[User].store(user)
        User.me = user
      end

      def prepared_tinder_room(room)
        tinder_room = Room.get_tinder_room_by_id_or_name(room)
        raise "Can't find \"#{room}\" room. Aborting" if tinder_room.blank?

        room = Room.new(id: tinder_room.id, name: tinder_room.name, tinder_room: tinder_room)
        Repository[Room].store(room)

        tinder_room
      end
    end
  end

end
