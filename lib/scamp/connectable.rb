class Scamp
  module Connectable
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def connect!(rooms_in_loose_format, &blk)
        logger.info "Starting up"

        campfire = ::Tinder::Campfire.new ::Scamp.subdomain, :token => ::Scamp.subdomain

        join(campfire)

        prepared_tinder_rooms(rooms_in_loose_format, campfire).each do |room|
          room.listen &process_message
        end
      end

      private

      def join(campfire)
        user = User.make(campfire.me)
        Repository[User].store(user)
        User.me = user
      end

      def prepared_tinder_rooms(rooms, campfire)
        tinder_rooms = []

        rooms.collect do |room|
          if room.kind_of?(Integer)
            tinder_room = campfire.find_room_by_id(room)
          else
            tinder_room = campfire.find_room_by_name(room)
          end
          Repository[Room].store(Room.new(id: tinder_room.id, name: tinder_room.name, tinder_room: tinder_room))

          tinder_rooms
        end
      end
    end
  end

end
