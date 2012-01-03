require 'ostruct'

class UserRepository
  @@users = []
  def self.add_user(user)
    puts "add user: #{user.inspect}"
    @@users << user
  end

  def self.get(id_or_name)
    if id_or_name.kind_of?(Integer)
      @@users.detect { |e| e.id == id_or_name }
    elsif id_or_name.kind_of?(String)
      @@users.detect { |e| e.name == id_or_name }
    else
      raise 'unknown identifier type'
    end
  end

  def self.fetch_user_data(user_id)
    return unless user_id
    url = "https://#{::Scamp.subdomain}.campfirenow.com/users/#{user_id}.json"
    http = EventMachine::HttpRequest.new(url).get(:head => {'authorization' => [::Scamp.api_key, 'X'], "Content-Type" => "application/json"})
    http.callback do
      if http.response_header.status == 200
        #logger.debug "Got the data for #{user_id}"
        puts "Got the data for #{user_id}"
        add_user(Room.new(id: user_id, name: Yajl::Parser.parse(http.response)['user']['name']))
      else
        #logger.error "Couldn't fetch user data for user #{user_id} with url #{url}, http response from API was #{http.response_header.status}"
        puts "Couldn't fetch user data for user #{user_id} with url #{url}, http response from API was #{http.response_header.status}"
      end
    end
    http.errback do
      #logger.error "Couldn't connect to #{url} to fetch user data for user #{user_id}"
      puts "Couldn't connect to #{url} to fetch user data for user #{user_id}"
    end
  end
end

