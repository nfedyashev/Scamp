class Scamp
  class Room < OpenStruct
    def initialize(hash)
      raise ':id is not set'   unless hash.keys.include?(:id)
      raise ':name is not set' unless hash.keys.include?(:name)

      super(hash)
    end

    def self.make(hash)
      Room.new(id: hash['id'], name: hash['name'])
    end

    def self.get_tinder_room_by_id_or_name(value)
      campfire = ::Scamp.tinder_campfire
      raise 'Please connect to Campfire first' if campfire.blank?

      if value.kind_of?(Integer)
        tinder_room = campfire.find_room_by_id(value)
      else
        tinder_room = campfire.find_room_by_name(value)
      end

      return nil if tinder_room.blank?

      unless is_in_repo = get_by_id_or_name(value)
        room = Room.new(id: tinder_room.id, name: tinder_room.name, tinder_room: tinder_room)
        ::Repository[Room].store(room)
      end

      tinder_room
    end

    def self.get_by_id_or_name(value)
      c = Repository::Criterion::Or.new(
        Repository::Criterion::Equals.new(:subject => "id",   :value => value),
        Repository::Criterion::Equals.new(:subject => "name", :value => value)
      )

      Repository[Room].search(c).first
    end

    def say(message)
      tinder_room.speak(message)
    end

    def play(sound)
      tinder_room.play(sound)
    end
  end
end
