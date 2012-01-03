require "spec_helper"

describe Scamp do

  describe "matching" do
    it "should make the room details available to the action block" do
      @user1 = Room.new(id: 456, name: 'User 1')
      @room1 = Room.new(id: 123, name: 'Room 1')

      message = Scamp::Message.new({:room => @room1, :user => @user1, :body => "a string"})
      blk = Proc.new {}
      action = Scamp::Action.new(blk, message)

      action.room_id.should == @room1.id
      action.room.should == @room1.name

      action.user_id.should == @user1.id
      action.user.should == @user1.name

      action.message.should == 'a string'
    end
  end
end
