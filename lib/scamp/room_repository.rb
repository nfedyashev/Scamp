require 'ostruct'
require 'active_support/core_ext/hash'

class RoomRepository
  @@rooms = []
  def self.add_room(room)
    puts "add room: #{room.inspect}"
    @@rooms << room
  end

  def self.get(id_or_name)
    if id_or_name.kind_of?(Integer)
      @@rooms.detect { |e| e.id == id_or_name }
    elsif id_or_name.kind_of?(String)
      @@rooms.detect { |e| e.name == id_or_name }
    else
      raise 'unknown identifier type'
    end
  end

  def self.fetch_room_data(room_id)
    url = "https://#{::Scamp.subdomain}.campfirenow.com/room/#{room_id}.json"
    http = EventMachine::HttpRequest.new(url).get :head => {'authorization' => [::Scamp.api_key, 'X']}
    #http.errback { logger.error "Couldn't connect to #{url} to fetch room data for room #{room_id}" }
    http.errback { puts "Couldn't connect to #{url} to fetch room data for room #{room_id}" }
    http.callback {
      if http.response_header.status == 200
        #logger.debug "Fetched room data for #{room_id}"
        puts "Fetched room data for #{room_id}"
        room_name = Yajl::Parser.parse(http.response)['room']
        #room_cache[room["id"]] = room

        add_room(Room.new(id: room_id, name: room_name))

        #room['users'].each do |u|
        #  update_user_cache_with(u["id"], u)
        #end
      else
        #logger.error "Couldn't fetch room data for room #{room_id} with url #{url}, http response from API was #{http.response_header.status}"
        puts "Couldn't fetch room data for room #{room_id} with url #{url}, http response from API was #{http.response_header.status}"
      end
    }
  end
end

class Scamp
  module Rooms
    # TextMessage (regular chat message),
    # PasteMessage (pre-formatted message, rendered in a fixed-width font),
    # SoundMessage (plays a sound as determined by the message, which can be either “rimshot”, “crickets”, or “trombone”),
    # TweetMessage (a Twitter status URL to be fetched and inserted into the chat)

    def upload
    end
    
    def join(room_id)
      #logger.info "Joining room #{room_id}"
      puts "Joining room #{room_id}"
      url = "https://#{subdomain}.campfirenow.com/room/#{room_id}/join.json"
      http = EventMachine::HttpRequest.new(url).post :head => {'Content-Type' => 'application/json', 'authorization' => [api_key, 'X']}
      
      #http.errback { logger.error "Error joining room: #{room_id}" }
      http.errback { puts "Error joining room: #{room_id}" }
      http.callback {
        yield if block_given?
      }
    end

    #def room_id(room_id_or_name)
    #  if room_id_or_name.is_a? Integer
    #    return room_id_or_name
    #  else
    #    return room_id_from_room_name(room_id_or_name)
    #  end
    #end
    
    #def room_name_for(room_id)
    #  data = room_cache_data(room_id)
    #  return data["name"] if data
    #  room_id.to_s
    #end
    
    #def room_cache_data(room_id)
    #  return room_cache[room_id] if room_cache.has_key? room_id
    #  fetch_room_data(room_id)
    #  return false
    #end
    
    def self.populate_room_list
      url = "https://#{::Scamp.subdomain}.campfirenow.com/rooms.json"
      http = EventMachine::HttpRequest.new(url).get :head => {'authorization' => [::Scamp.api_key, 'X']}
      #http.errback { logger.error "Couldn't connect to url #{url} to fetch room list" }
      http.errback { puts "Couldn't connect to url #{url} to fetch room list" }
      http.callback {
        if http.response_header.status == 200
          #logger.debug "Fetched room list"
          puts "Fetched room list"
          new_rooms = {}
          Yajl::Parser.parse(http.response)['rooms'].each do |c|
            new_rooms[c["name"]] = c
            RoomRepository.add_room(Room.new(c.symbolize_keys))
          end
          # No idea why using the "rooms" accessor here doesn't
          # work but accessing the ivar directly does. There's
          # Probably a bug.
          @rooms = new_rooms # replace existing room list
          yield if block_given?
        else
          #logger.error "Couldn't fetch room list with url #{url}, http response from API was #{http.response_header.status}"
          puts "Couldn't fetch room list with url #{url}, http response from API was #{http.response_header.status}"
        end
      }
    end
    
    def self.join_and_stream(room)
      join(room.id) do
        #logger.info "Joined room #{room.name}(#{room.id}) successfully"
        puts "Joined room #{room.name}(#{room.id}) successfully"
        RoomRepository.fetch_room_data(room.id)
        stream(room)
      end
    end
    
    def self.stream(room)
      json_parser = Yajl::Parser.new :symbolize_keys => true
      json_parser.on_parse_complete = method(:process_message)
      
      url = "https://streaming.campfirenow.com/room/#{room.id}/live.json"
      # Timeout per https://github.com/igrigorik/em-http-request/wiki/Redirects-and-Timeouts
      http = EventMachine::HttpRequest.new(url, :connect_timeout => 20, :inactivity_timeout => 0).get :head => {'authorization' => [api_key, 'X']}
      #http.errback { logger.error "Couldn't stream room #{room.id} at url #{url}" }
      http.errback { puts "Couldn't stream room #{room.id} at url #{url}" }
      #http.callback { logger.info "Disconnected from #{url}"; rooms_to_join << room}
      http.callback { puts "Disconnected from #{url}"; rooms_to_join << room}
      http.stream {|chunk| json_parser << chunk }
    end

    #def room_id_from_room_name(room_name)
    #  logger.debug "Looking for room id for #{room_name}"
    #  rooms[room_name]["id"]
    #end
  end
end
