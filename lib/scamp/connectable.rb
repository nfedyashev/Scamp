class Scamp
  module Connectable
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def connect!(room_list, &blk)
        logger.info "Starting up"
        connect(room_list, &blk)
      end

      private

      def connect(room_list, &blk)
        EventMachine.run do

          # Check for rooms to join, and join them
          EventMachine::add_periodic_timer(5) do
            while room = @rooms_to_join.pop
              ::Scamp::Rooms.join_and_stream(room)
            end
          end

          populate_room_list do
            logger.debug "Adding #{room_list.join ', '} to list of rooms to join"
            @rooms_to_join = room_list.map{ |c| RoomRepository.get(c) }

            # Call a post connection block
            if block_given?
              yield
            end
          end

          # populate bot data separately, in case we are ignoring ourselves
          UserRepository.fetch_user_data('me')
        end
      end

    end
  end

end
