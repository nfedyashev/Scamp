
class Scamp
  module Connectable
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def connect!(rooms, &blk)
        #logger.info "Starting up"
        puts "Starting up"

        campfire = ::Tinder::Campfire.new 'nfedyashev', :token => 'ed198ff06013829a4a2b870e057993486dee41e3'

        user = User.make(campfire.me)
        Repository[User].store(user)
        User.me = user

        tinder_rooms = []

        rooms.each do |room|
          if room.kind_of?(Integer)
            tinder_room = campfire.find_room_by_id(room)
          else
            tinder_room = campfire.find_room_by_name(room)
          end
          tinder_rooms << tinder_room

          Repository[Room].store(Room.new(id: tinder_room.id, name: tinder_room.name, tinder_room: tinder_room))
        end

        tinder_rooms.each do |room|
          room.listen &process_message
        end

      end
    end
  end

end
