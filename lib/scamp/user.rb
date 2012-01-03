require 'ostruct'

class User < OpenStruct
  def initialize(hash)
    raise ':id is not set' unless hash.keys.include?(:id)
    raise ':name is not set' unless hash.keys.include?(:id)

    super(hash)
  end
end
