require 'ostruct'

class Scamp
  class Message < OpenStruct
    def initialize(hash)
      puts hash.inspect
      raise ':user is not set' unless hash.keys.include?(:user)
      raise ':room is not set' unless hash.keys.include?(:room)
      raise ':body is not set' unless hash.keys.include?(:body)

      super(hash)
    end

    def self.make(hash)
      Scamp::Message.new(:user => UserRepository.get(hash[:user_id]), :room => RoomRepository.get(hash[:room_id]), :body => hash[:body])
    end
  end
end
