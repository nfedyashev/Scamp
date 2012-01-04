require "spec_helper"

describe Scamp::Room do
  it 'speaks' do
    tinder_room = mock
    tinder_room.expects(:speak).with('foo')

    room1 = Scamp::Room.new(id: 123, name: 'Room 1', :tinder_room => tinder_room)
    room1.say('foo')
  end

  it 'plays' do
    tinder_room = mock
    tinder_room.expects(:play).with('yeah')

    room1 = Scamp::Room.new(id: 123, name: 'Room 1', :tinder_room => tinder_room)
    room1.play('yeah')
  end
end
