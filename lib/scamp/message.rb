class Scamp
  class Message < OpenStruct
    def initialize(hash)
      raise ':user is not set' unless hash.keys.include?(:user)
      raise ':room is not set' unless hash.keys.include?(:room)
      raise ':body is not set' unless hash.keys.include?(:body)

      super(hash)
    end

    def self.make(hash)
      room = Repository[Room].search(hash['room_id']).first

      Scamp::Message.new(:user => User.find_or_create(hash), :room => room, :body => hash['body'])
    end
  end
end
