require 'ostruct'

class Room < OpenStruct
  def initialize(hash)
    raise ':id is not set'   unless hash.keys.include?(:id)
    raise ':name is not set' unless hash.keys.include?(:name)

    super(hash)
  end

  def self.make(hash)
    Room.new(id: hash['id'], name: hash['name'])
  end

  def self.get_by_id_or_name(value)
    c = Repository::Criterion::Or.new(
      Repository::Criterion::Equals.new(:subject => "id",   :value => value),
      Repository::Criterion::Equals.new(:subject => "name", :value => value)
    )

    Repository[Room].search(c).first
  end

  def play(sound)
    tinder_room.play(sound)
  end
end
