require "spec_helper"

describe Scamp do
  before do
    @valid_params = {:api_key => "6124d98749365e3db2c9e5b27ca04db6", :subdomain => "oxygen"} 
    @valid_user_cache_data = {123 => {"name" => "foo"}, 456 => {"name" => "bar"}, 'me' => {"name" => "bot", "id" => 123}}
    
    # Stub fetch for room data
    @valid_room_cache_data = {
      123 => {
        "id" => 123,
        "name" => "foo",
        "users" => []
      },
      456 => {
        "id" => 456,
        "name" => "bar",
        "users" => []
      }
    }
  end
  
  describe "#initialize" do
    it "should work with valid params" do
      a(Scamp).should be_a(Scamp)
    end
    it "should warn if given an option it doesn't know" do
      mock_logger

      a(Scamp, :fred => "estaire").should be_a(Scamp)

      logger_output.should =~ /WARN.*Scamp initialized with :fred => "estaire" but NO UNDERSTAND!/
    end
  end

  describe "#verbose" do
    it "should default to false" do
      a(Scamp).verbose.should be_false
    end
    it "should be overridable at initialization" do
      a(Scamp, :verbose => true).verbose.should be_true
    end
  end

  describe "#logger" do
    context "default logger" do
      before { @bot = a Scamp }
      it { @bot.logger.should be_a(Logger) }
      it { @bot.logger.level.should be == Logger::INFO }
    end
    context "default logger in verbose mode" do
      before { @bot = a Scamp, :verbose => true }
      it { @bot.logger.level.should be == Logger::DEBUG }
    end
    context "overriding default" do
      before do
        @custom_logger = Logger.new("/dev/null")
        @bot = a Scamp, :logger => @custom_logger
      end
      it { @bot.logger.should be == @custom_logger }
    end
  end

  describe "#first_match_only" do
    it "should default to false" do
      a(Scamp).first_match_only.should be_false
    end
    it "should be settable" do
      a(Scamp, :first_match_only => true).first_match_only.should be_true
    end
  end

  describe "private methods" do

    describe "#process_message" do
      before do
        @bot = a Scamp
        $attempts = 0 # Yes, I hate it too. Works though.
        @message = {:body => "my message here"}

        @bot.behaviour do
          2.times { match(/.*/) { $attempts += 1 } }
        end
      end
      after { $attempts = nil }
      context "with first_match_only not set" do
        before { @bot.first_match_only.should be_false }
        it "should process all matchers which attempt the message" do
          @bot.send(:process_message, @message)
          $attempts.should be == 2
        end
      end
      context "with first_match_only set" do
        before do
          @bot.first_match_only = true
          @bot.first_match_only.should be_true
        end
        it "should only process the first matcher which attempts the message" do
          @bot.send(:process_message, @message)
          $attempts.should be == 1
        end
      end
    end
  end
  
  describe "matching" do
    before do
      @room1 = Room.new(id: 123, name: 'Room 1')
      RoomRepository.add_room(@room1)

      @user1 = User.new(id: 123, name: 'User 1')
      UserRepository.add_user(@user1)
    end

    context "with conditions" do

      context "for room" do
        it "should limit matches by id" do
          room2 = Room.new(id: 456, name: 'Room 2')
          RoomRepository.add_room(room2)

          message = Scamp::Message.new({:room => @room1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 123})
          matcher.matches?(message).should be_true

          message = Scamp::Message.new({:room_id => room2, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 123})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by array of IDs" do
          room2 = Room.new(id: 456, name: 'Room 2')
          RoomRepository.add_room(room2)

          message = Scamp::Message.new({:room => @room1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => [123]})
          matcher.matches?(message).should be_true


          message = Scamp::Message.new({:room_id => room2, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => [123]})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by array in complex form" do
          message = Scamp::Message.new({:room => @room1, :body => "a string"})

          matcher = Scamp::Expectation.new("a string", :conditions => {:rooms => [@room1.name, 777]})
          matcher.matches?(message).should be_true

          matcher = Scamp::Expectation.new("a string", :conditions => {:rooms => ['bar']})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by name" do
          message = Scamp::Message.new({:room => @room1, :body => "a string"})

          matcher = Scamp::Expectation.new("a string", :conditions => {:room => @room1.name})
          matcher.matches?(message).should be_true

          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 'bar'})
          matcher.matches?(message).should be_false
        end

      end

      context "for user" do
        before do
          @user1 = User.new(id: 123, name: 'User 1')
          UserRepository.add_user(@user1)
        end

        it "should limit matches by user id" do
          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:user => @user1.id})
          matcher.matches?(message).should be_true

          matcher = Scamp::Expectation.new("a string", :conditions => {:user => 0})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by user name" do
          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:user => @user1.name})
          matcher.matches?(message).should be_true

          matcher = Scamp::Expectation.new("a string", :conditions => {:user => 'invalid'})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by room and user" do
          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:user => @user1.id, :room => @room1.id})
          matcher.matches?(message).should be_true

          matcher = Scamp::Expectation.new("a string", :conditions => {:user => @user1.id, :room => 456})
          matcher.matches?(message).should be_false
        end

        it "should ignore itself if so requested" do
          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :ignore_self => true, :conditions => {:user => @user1.name})
          matcher.matches?(message).should be_true
        end
      end
    end
    
    describe "strings" do
      it "should match an exact string" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})

        matcher = Scamp::Expectation.new("a string", :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_true

        matcher = Scamp::Expectation.new("another string", :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_false

        matcher = Scamp::Expectation.new("a string like no another", :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_false
      end
      
      it "should not match without prefix when required_prefix is true" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})

        matcher = Scamp::Expectation.new("a string", :required_prefix => 'Bot: ', :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_false
      end

      it "should match with exact prefix when required_prefix is true" do
        raise 'fixme'
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "Bot: a string"})

        matcher = Scamp::Expectation.new("a string", :required_prefix => 'Bot: ', :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_true
      end
    end

    describe "regexes" do
      it "should match a regex" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "something foo other thing"})
        matcher = Scamp::Expectation.new(/foo/, :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_true

        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "foomaster"})
        matcher = Scamp::Expectation.new(/foo/, :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_true
      end
      
      it "should make named captures vailable as methods" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "please match first and the rest of it"})
        matcher = Scamp::Expectation.new(/^please match (?<yousaidthis>\w+) and (?<andthis>.+)$/, :conditions => {:user => @user1.name})

        matcher.matches?(message).should be_true

        matcher.matches['yousaidthis'].should == "first"
        matcher.matches['andthis'].should == "the rest of it"
      end
      
      it "should make matches available in an array" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "please match first and the rest of it"})
        matcher = Scamp::Expectation.new(/^please match (\w+) and (.+)$/, :conditions => {:user => @user1.name})

        matcher.matches?(message).should be_true
        matcher.matches[1..-1].should == ["first", "the rest of it"]
      end
      
      it "should not match without prefix when required_prefix is present" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
        matcher = Scamp::Expectation.new(/a string/, :required_prefix => /^Bot[\:,\s]+/i, :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_false


        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "some kind of a string"})
        matcher = Scamp::Expectation.new(/a string/, :required_prefix => /^Bot[\:,\s]+/i, :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_false
      end

      it "should match with regex prefix when required_prefix is present" do
        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "Bot, a string"})
        matcher = Scamp::Expectation.new(/a string/, :required_prefix => /^Bot\W{1,2}/i, :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_true

        message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "bot: a string"})
        matcher = Scamp::Expectation.new(/a string/, :required_prefix => /^Bot\W{1,2}/i, :conditions => {:user => @user1.name})
        matcher.matches?(message).should be_true
      end
    end
  end
  
  describe "match block" do
    
    it "should provide a command list" do
      canary = mock
      canary.expects(:commands).with([["Hello world", {}], ["Hello other world", {:room=>123}], [/match me/, {:user=>123}]])
      
      bot = a Scamp
      bot.behaviour do
        match("Hello world") {
          canary.commands(command_list)
        }
        match("Hello other world", :conditions => {:room => 123}) {}
        match(/match me/, :conditions => {:user => 123}) {}
      end
      
      bot.send(:process_message, {:body => "Hello world"})
    end
    
    it "should be able to play a sound to the room the action was triggered in" do
      bot = a Scamp
      bot.behaviour do
        match("Hello world") {
          play "yeah"
        }
      end
      
      EM.run_block {
        room_id = 123
        stub_request(:post, "https://#{@valid_params[:subdomain]}.campfirenow.com/room/#{room_id}/speak.json").
          with(
            :body => "{\"message\":{\"body\":\"yeah\",\"type\":\"SoundMessage\"}}",
            :headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}
          )
            
        bot.send(:process_message, {:room_id => room_id, :body => "Hello world"})
      }
    end
    
    it "should be able to play a sound to an arbitrary room" do
      play_room = 456
      
      bot = a Scamp
      bot.behaviour do
        match("Hello world") {
          play "yeah", play_room
        }
      end
      
      EM.run_block {
        room_id = 123
        stub_request(:post, "https://#{@valid_params[:subdomain]}.campfirenow.com/room/#{play_room}/speak.json").
          with(
            :body => "{\"message\":{\"body\":\"yeah\",\"type\":\"SoundMessage\"}}",
            :headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}
          )
            
        bot.send(:process_message, {:room_id => room_id, :body => "Hello world"})
      }
    end
    
    it "should be able to say a message to the room the action was triggered in" do
      bot = a Scamp
      bot.behaviour do
        match("Hello world") {
          say "yeah"
        }
      end
      
      EM.run_block {
        room_id = 123
        stub_request(:post, "https://#{@valid_params[:subdomain]}.campfirenow.com/room/#{room_id}/speak.json").
          with(
            :body => "{\"message\":{\"body\":\"yeah\",\"type\":\"Textmessage\"}}",
            :headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}
          )
            
        bot.send(:process_message, {:room_id => room_id, :body => "Hello world"})
      }
    end
    
    it "should be able to say a message to an arbitrary room" do
      play_room = 456
      
      bot = a Scamp
      bot.behaviour do
        match("Hello world") {
          say "yeah", play_room
        }
      end
      
      EM.run_block {
        room_id = 123
        stub_request(:post, "https://#{@valid_params[:subdomain]}.campfirenow.com/room/#{play_room}/speak.json").
          with(
            :body => "{\"message\":{\"body\":\"yeah\",\"type\":\"Textmessage\"}}",
            :headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}
          )
            
        bot.send(:process_message, {:room_id => room_id, :body => "Hello world"})
      }
    end
  end

  describe "API" do
    context "user operations" do
      it "should fetch user data" do
        bot = a Scamp
        
        EM.run_block {
          stub_request(:get, "https://#{@valid_params[:subdomain]}.campfirenow.com/users/123.json").
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}).
            to_return(:status => 200, :body => Yajl::Encoder.encode(:user => @valid_user_cache_data[123]), :headers => {})
          bot.username_for(123)
        }
      end
      
      it "should handle HTTP errors fetching user data" do
        mock_logger
        bot = a Scamp

        url = "https://#{@valid_params[:subdomain]}.campfirenow.com/users/123.json"
        EM.run_block {
          stub_request(:get, url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}).
            to_return(:status => 502, :body => "", :headers => {'Content-Type'=>'text/html'})
          lambda {bot.username_for(123)}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't fetch user data for user 123 with url #{url}, http response from API was 502/
      end
      
      it "should handle network errors fetching user data" do
        mock_logger
        bot = a Scamp
        
        url = "https://#{@valid_params[:subdomain]}.campfirenow.com/users/123.json"
        EM.run_block {
          stub_request(:get, url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}).to_timeout
          lambda {bot.username_for(123)}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't connect to #{url} to fetch user data for user 123/
      end
    end
    
    context "room operations" do
      before do
        @room_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/rooms.json"
        @me_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/users/me.json"
        @room_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/room/123.json"
        @stream_url = "https://streaming.campfirenow.com/room/123/live.json"
      end
      
      it "should fetch a room list" do
        mock_logger
        bot = a Scamp
        
        EM.run_block {
          stub_request(:get, @room_list_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X']}).
            to_return(:status => 200, :body => Yajl::Encoder.encode(:rooms => @valid_room_cache_data.values), :headers => {})
          bot.send(:populate_room_list)
        }
        logger_output.should =~ /DEBUG.*Fetched room list/
      end

      it "should invoke the post connection callback" do
        mock_logger
        bot = a Scamp

        invoked_cb = false

        EM.run_block {
          stub_request(:get, @room_list_url).
          with(:headers => {
                 'Authorization'=>[@valid_params[:api_key], 'X'],
                 'Content-Type' => 'application/json'
               }).
          to_return(:status => 200, :body => Yajl::Encoder.encode(:rooms => @valid_room_cache_data.values), :headers => {})

          stub_request(:get, @room_list_url).
          with(:headers => {
                 'Authorization'=>[@valid_params[:api_key], 'X']
               }).
          to_return(:status => 200, :body => Yajl::Encoder.encode(:rooms => @valid_room_cache_data.values), :headers => {})

          # Disable fetch_data_for, not important to this test.
          Scamp.any_instance.expects(:fetch_data_for).returns(nil)

          bot.send(:connect!, [@valid_room_cache_data.keys.first]) do
            invoked_cb = true
          end
        }
        invoked_cb.should be_true
      end

      it "should handle HTTP errors fetching the room list" do
        mock_logger
        bot = a Scamp
      
        EM.run_block {
          # stub_request(:get, url).
          #   with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}).
          #   to_return(:status => 502, :body => "", :headers => {'Content-Type'=>'text/html'})
          stub_request(:get, @room_list_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X']}).
            to_return(:status => 502, :body => "", :headers => {'Content-Type'=>'text/html'})
          lambda {bot.send(:populate_room_list)}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't fetch room list with url #{@room_list_url}, http response from API was 502/
      end
      
      it "should handle network errors fetching the room list" do
        mock_logger
        bot = a Scamp
        EM.run_block {
          stub_request(:get, @room_list_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X']}).to_timeout
          lambda {bot.send(:populate_room_list)}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't connect to url #{@room_list_url} to fetch room list/
      end
      
      it "should fetch individual room data" do
        mock_logger
        bot = a Scamp
        
        EM.run_block {
          stub_request(:get, @room_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X']}).
            to_return(:status => 200, :body => Yajl::Encoder.encode(:room => @valid_room_cache_data[123]), :headers => {})
          bot.room_name_for(123)
        }
        logger_output.should =~ /DEBUG.*Fetched room data for 123/
      end
      
      it "should handle HTTP errors fetching individual room data" do
        mock_logger
        bot = a Scamp

        EM.run_block {
          stub_request(:get, @room_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X']}).
            to_return(:status => 502, :body => "", :headers => {'Content-Type'=>'text/html'})
          lambda {bot.room_name_for(123)}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't fetch room data for room 123 with url #{@room_url}, http response from API was 502/
      end
      
      it "should handle network errors fetching individual room data" do
        mock_logger
        bot = a Scamp
        
        EM.run_block {
          stub_request(:get, @room_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X']}).to_timeout
          lambda {bot.room_name_for(123)}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't connect to #{@room_url} to fetch room data for room 123/
      end
      
      it "should stream a room"
      it "should handle HTTP errors streaming a room"
      it "should handle network errors streaming a room"
    end
    
    context "message operations" do
      before do
        @message_post_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/room/123/speak.json"
      end

      it "should send a message" do
        mock_logger
        bot = a Scamp
        
        EM.run_block {
          stub_request(:post, @message_post_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).
            to_return(:status => 201, :body => Yajl::Encoder.encode(:room => @valid_room_cache_data[123]), :headers => {})
          bot.send(:send_message, 123, "Hi", "Textmessage")
        }
        logger_output.should =~ /DEBUG.*Posted message "Hi" to room 123/
      end

      it "should paste a message" do
        mock_logger
        bot = a Scamp

        EM.run_block {
          stub_request(:post, @message_post_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).
            to_return(:status => 201, :body => Yajl::Encoder.encode(:room => @valid_room_cache_data[123]), :headers => {})
          bot.send(:send_message, 123, "Hi", "PasteMessage")
        }
        logger_output.should =~ /DEBUG.*Posted message "Hi" to room 123/
      end

      it "should handle HTTP errors fetching individual room data" do
        mock_logger
        bot = a Scamp

        EM.run_block {
          stub_request(:post, @message_post_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).
            to_return(:status => 502, :body => "", :headers => {'Content-Type'=>'text/html'})
          lambda {bot.send(:send_message, 123, "Hi", "Textmessage")}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't post message "Hi" to room 123 using url #{@message_post_url}, http response from the API was 502/
      end
      
      it "should handle network errors fetching individual room data" do
        mock_logger
        bot = a Scamp
        
        EM.run_block {
          stub_request(:post, @message_post_url).
            with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).to_timeout
          lambda {bot.send(:send_message, 123, "Hi", "Textmessage")}.should_not raise_error
        }
        logger_output.should =~ /ERROR.*Couldn't connect to #{@message_post_url} to post message "Hi" to room 123/
      end
    end
  end

  def a klass, params={}
    params ||= {}
    params = @valid_params.merge(params) if klass == Scamp
    klass.new(params)
  end

  # Urg
  def mock_logger
    @logger_string = StringIO.new
    @fake_logger = Logger.new(@logger_string)
    Scamp.any_instance.expects(:logger).at_least(1).returns(@fake_logger)
  end

  # Bleurgh
  def logger_output
    str = @logger_string.dup
    str.rewind
    str.read
  end
end
