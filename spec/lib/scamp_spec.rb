require "spec_helper"

describe Scamp do
  before do
    @valid_params = {:api_key => "6124d98749365e3db2c9e5b27ca04db6", :subdomain => "oxygen"} 
  end

  before(:each) do
    Repository[Scamp::Room].clear
  end

  describe "#verbose" do
    it "should default to false" do
      Scamp.verbose.should be_false
    end
  end

  describe "#logger" do
    context "default logger" do
      it { Scamp.logger.should be_a(Logger) }
      it { Scamp.logger.level.should be == Logger::DEBUG }
    end
  end

  describe "#first_match_only" do
    it "should default to false" do
      Scamp.first_match_only.should be_false
    end
  end

  describe "private methods" do
    before do
      @room1 = Scamp::Room.new(id: 123, name: 'Room 1')
      Repository[Scamp::Room].store(@room1)

      @user1 = Scamp::User.new(id: 123, name: 'User 1')
      Repository[Scamp::User].store(@user1)
    end

    describe "#process_message" do
      before do
        @bot = a Scamp
        $attempts = 0 # Yes, I hate it too. Works though.

        @message = {'user_id' => @user1.id, 'room_id' => @room1.id, 'body' => "my message here", 'type' => 'TextMessage'}

        @bot.behaviour do
          2.times { match(/.*/) { $attempts += 1 } }
        end
      end

      after { $attempts = nil }

      context "with first_match_only not set" do
        before { Scamp.first_match_only.should be_false }
        it "should process all matchers which attempt the message" do
          @bot.process_message.call(@message)
          $attempts.should be == 2
        end
      end

      context "with first_match_only set" do
        before do
          Scamp.first_match_only = true
          Scamp.first_match_only.should be_true
        end
        it "should only process the first matcher which attempts the message" do
          @bot.process_message.call(@message)
          $attempts.should be == 1
        end
      end
    end
  end

  describe "matching" do
    before do
      @room1 = ::Scamp::Room.new(id: 123, name: 'Room 1')
      Repository[::Scamp::Room].store(@room1)

      @user1 = ::Scamp::User.new(id: 123, name: 'User 1')
      Repository[::Scamp::User].store(@user1)
    end

    context "with conditions" do

      context "for room" do
        it "should limit matches by id" do
          room2 = ::Scamp::Room.new(id: 456, name: 'Room 2')
          Repository[::Scamp::Room].store(room2)

          message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 123})
          matcher.matches?(message).should be_true

          message = Scamp::Message.new({:room => room2, :user => @user1, :body => "a string"})
          matcher = Scamp::Expectation.new("a string", :conditions => {:room => 123})
          matcher.matches?(message).should be_false
        end

        it "should limit matches by array of IDs" do
          room2 = ::Scamp::Room.new(id: 456, name: 'Room 2')
          Repository[::Scamp::Room].store(room2)

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
          @user1 = ::Scamp::User.new(id: 123, name: 'User 1')
          Repository[::Scamp::User].store(@user1)
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
      Repository[Room].store(@room1)

      @user1 = ::Scamp::User.new(id: 123, name: 'User 1')
      Repository[::Scamp::User].store(@user1)
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
