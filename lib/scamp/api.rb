class Scamp
  module API

    def self.say(message, room)
      send_message(room, message, "Textmessage")
    end

    def self.paste(message, room)
      send_message(room, message, "PasteMessage")
    end

    def self.play(sound, room)
      send_message(room, sound, "SoundMessage")
    end

    #  curl -vvv -H 'Content-Type: application/json' -d '{"message":{"body":"Yeeeeeaaaaaahh", "type":"Textmessage"}}' -u API_KEY:X https://37s.campfirenow.com/room/293788/speak.json
    def self.send_message(room, payload, type)
      # post 'speak', :body => {:message => {:body => message, :type => type}}.to_json
      url = "https://#{::Scamp.subdomain}.campfirenow.com/room/#{room.id}/speak.json"
      http = EventMachine::HttpRequest.new(url).post :head => {'Content-Type' => 'application/json', 'authorization' => [::Scamp.api_key, 'X']}, :body => Yajl::Encoder.encode({:message => {:body => payload, :type => type}})
      #http.errback { logger.error "Couldn't connect to #{url} to post message \"#{payload}\" to room #{room.id}" }
      http.errback { puts "Couldn't connect to #{url} to post message \"#{payload}\" to room #{room.id}" }
      http.callback {
        if [200,201].include? http.response_header.status
          #logger.debug "Posted message \"#{payload}\" to room #{room.id}"
          puts "Posted message \"#{payload}\" to room #{room.id}"
        else
          #logger.error "Couldn't post message \"#{payload}\" to room #{room.id} using url #{url}, http response from the API was #{http.response_header.status}"
          puts "Couldn't post message \"#{payload}\" to room #{room.id} using url #{url}, http response from the API was #{http.response_header.status}"
        end
      }
    end
    private_class_method :send_message

  end
end
