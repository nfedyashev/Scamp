class Scamp
  class User < OpenStruct
    cattr_accessor :me

    def initialize(hash)
      raise ':id is not set' unless hash.keys.include?(:id)
      raise ':name is not set' unless hash.keys.include?(:name)

      super(hash)
    end

    def self.find_or_create(tinder_message)
      if user = Repository[User].search(tinder_message.user.id).first
        return user
      else
        #FIXME - check name format
        user = User.new(id: tinder_message.user.id, name: tinder_message.user.name)
        Repository[User].store(user)
        user
      end
    end

    def self.make(hash)
      User.new(id: hash['id'], name: hash['name'])
    end

    def self.get_by_id_or_name(value)
      c = Repository::Criterion::Or.new(
        Repository::Criterion::Equals.new(:subject => "id",   :value => value),
        Repository::Criterion::Equals.new(:subject => "name", :value => value)
      )

      Repository[User].search(c).first
    end
  end
end
