require "spec_helper"

describe Scamp do
  before(:each) do
    @user1 = Scamp::Room.new(id: 456, name: 'User 1')
    @room1 = Scamp::Room.new(id: 123, name: 'Room 1')

    @message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
  end

  describe Scamp::Action do
    describe 'configuration' do
      before do
        blk = lambda {}
        @action = Scamp::Action.new(blk, @message)
      end

      it "must set user method" do
        @action.user_id.should == @user1.id
        @action.user.should == @user1.name
      end

      it "must set room method" do
        @action.room_id.should == @room1.id
        @action.room.should == @room1.name
      end
    end

    it 'it can say' do
      @room1 = Scamp::Room.new(id: 123, name: 'Room 1', :tinder_room => stub_everything)
      @room1.expects(:say).with('foo')

      message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})

      blk = lambda {}
      @action = Scamp::Action.new(blk, message)
      @action.say('foo')
    end

    it 'it can play' do
      @room1 = Scamp::Room.new(id: 123, name: 'Room 1', :tinder_room => stub_everything)
      @room1.expects(:play).with('yeah')

      message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})

      blk = lambda {}
      @action = Scamp::Action.new(blk, message)
      @action.play('yeah')
    end

    describe 'matches' do
      pending
    end

    describe 'when runned' do
      before(:each) do
        $called = false
        blk = lambda { |_| $called = true }
        @action = Scamp::Action.new(blk, @message)
      end

      it 'executes block' do
        @action.run
        $called.should be_true
      end
    end
  end
  
end
