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
      a(Scamp)
      Scamp.verbose.should be_false
    end
    it "should be overridable at initialization" do
      a(Scamp, :verbose => true)
      Scamp.verbose.should be_true
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
      a(Scamp)
      Scamp.first_match_only.should be_false
    end
    it "should be settable" do
      a(Scamp, :first_match_only => true)
      Scamp.first_match_only.should be_true
    end
  end

  describe "private methods" do
    before do
      @room1 = Room.new(id: 123, name: 'Room 1')
      RoomRepository.add_room(@room1)

      @user1 = User.new(id: 123, name: 'User 1')
      UserRepository.add_user(@user1)
    end

    describe "#process_message" do
      before do
        @bot = a Scamp
        $attempts = 0 # Yes, I hate it too. Works though.
        @message = {:user_id => @user1.id, :room_id => @room1.id, :body => "my message here"}

        @bot.behaviour do
          2.times { match(/.*/) { $attempts += 1 } }
        end
      end
      after { $attempts = nil }
      context "with first_match_only not set" do
        before { Scamp.first_match_only.should be_false }
        it "should process all matchers which attempt the message" do
          @bot.send(:process_message, @message)
          $attempts.should be == 2
        end
      end
      context "with first_match_only set" do
        before do
          Scamp.first_match_only = true
          Scamp.first_match_only.should be_true
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

          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 123})
          matcher.matches?(message).should be_true

          message = Scamp::Message.new({:room => room2, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 123})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by array of IDs" do
          room2 = Room.new(id: 456, name: 'Room 2')
          RoomRepository.add_room(room2)

          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => [123]})
          matcher.matches?(message).should be_true


          message = Scamp::Message.new({:room => room2, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => [123]})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by array in complex form" do
          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})

          matcher = Scamp::Expectation.new("a string", :conditions => {:rooms => [@room1.name, 777]})
          matcher.matches?(message).should be_true

          matcher = Scamp::Expectation.new("a string", :conditions => {:rooms => ['bar']})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by name" do
          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})

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
    before do
      @room1 = Room.new(id: 123, name: 'Room 1')
      RoomRepository.add_room(@room1)

      @user1 = User.new(id: 123, name: 'User 1')
      UserRepository.add_user(@user1)
    end
    
    #it "should provide a command list" do
    #  canary = mock
    #  canary.expects(:commands).with([["Hello world", {}], ["Hello other world", {:room=>123}], [/match me/, {:user=>123}]])
    #  
    #  bot = a Scamp
    #  bot.behaviour do
    #    match("Hello world") {
    #      canary.commands(command_list)
    #    }
    #    match("Hello other world", :conditions => {:room => 123}) {}
    #    match(/match me/, :conditions => {:user => 123}) {}
    #  end
    #  
    #  bot.send(:process_message, {:body => "Hello world"})
    #end
    
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
            
        bot.send(:process_message, {:room_id => room_id, :user_id => 123, :body => "Hello world"})
      }
    end
    
    #it "should be able to play a sound to an arbitrary room" do
    #  play_room = 456
    #  
    #  bot = a Scamp
    #  bot.behaviour do
    #    match("Hello world") {
    #      play "yeah", play_room
    #    }
    #  end
    #  
    #  EM.run_block {
    #    room_id = 123
    #    stub_request(:post, "https://#{@valid_params[:subdomain]}.campfirenow.com/room/#{play_room}/speak.json").
    #      with(
    #        :body => "{\"message\":{\"body\":\"yeah\",\"type\":\"SoundMessage\"}}",
    #        :headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}
    #      )
    #        
    #    bot.send(:process_message, {:room_id => room_id, :user_id => @user1.id, :body => "Hello world"})
    #  }
    #end
    
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
            
        bot.send(:process_message, {:room_id => room_id, :user_id => @user1.id, :body => "Hello world"})
      }
    end
    
    #it "should be able to say a message to an arbitrary room" do
    #  play_room = 456
    #  
    #  bot = a Scamp
    #  bot.behaviour do
    #    match("Hello world") {
    #      say "yeah", play_room
    #    }
    #  end
    #  
    #  EM.run_block {
    #    room_id = 123
    #    stub_request(:post, "https://#{@valid_params[:subdomain]}.campfirenow.com/room/#{play_room}/speak.json").
    #      with(
    #        :body => "{\"message\":{\"body\":\"yeah\",\"type\":\"Textmessage\"}}",
    #        :headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type'=>'application/json'}
    #      )
    #        
    #    bot.send(:process_message, {:room_id => room_id, :user_id => @user1.id, :body => "Hello world"})
    #  }
    #end
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
