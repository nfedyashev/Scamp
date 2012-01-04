class Scamp
  class Message < OpenStruct
    def initialize(hash)
      raise ':user is not set' unless hash.keys.include?(:user)
      raise ':room is not set' unless hash.keys.include?(:room)
      raise ':body is not set' unless hash.keys.include?(:body)

      super(hash)
    end

    def self.make(tinder_message)
      room = Repository[Room].search(tinder_message['room_id']).first

      Scamp::Message.new(:user => User.find_or_create(tinder_message), :room => room, :body => tinder_message['body'])
    end
  end
end
