# encoding: UTF-8
class Scamp
  module Connectable
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def connect!(rooms_in_loose_format, &blk)
        logger.info "Starting up…"

        ::Scamp.tinder_campfire = ::Tinder::Campfire.new(::Scamp.subdomain, :token => ::Scamp.api_key)

        join_room

        prepared_tinder_rooms(rooms_in_loose_format).each do |room|
          logger.info "Listening to the room #{room.name}…"
          room.listen &process_message
        end
      end

      private

      def join_room
        user = User.make(::Scamp.tinder_campfire.me)
        Repository[User].store(user)
        User.me = user
      end

      def prepared_tinder_rooms(rooms)
        rooms.collect do |room|
          tinder_room = Room.get_tinder_room_by_id_or_name(room)

          room = Room.new(id: tinder_room.id, name: tinder_room.name, tinder_room: tinder_room)
          Repository[Room].store(room)

          tinder_room
        end
      end
    end
  end

end
