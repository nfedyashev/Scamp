require "spec_helper"

describe Scamp do
      
  context "room operations" do
    before do
      @valid_params = {:api_key => "6124d98749365e3db2c9e5b27ca04db6", :subdomain => "oxygen"} 
      Scamp.subdomain = @valid_params[:subdomain]
      Scamp.api_key   = @valid_params[:api_key]


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

      @room_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/rooms.json"
      @me_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/users/me.json"
      @room_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/room/123.json"
      @stream_url = "https://streaming.campfirenow.com/room/123/live.json"
    end

    #FIXME
    #it "should invoke the post connection callback" do
    #  #mock_logger

    #  invoked_cb = false

    #  EM.run_block {
    #    stub_request(:get, @room_list_url).
    #    with(:headers => {
    #           'Authorization'=>[@valid_params[:api_key], 'X'],
    #           'Content-Type' => 'application/json'
    #         }).
    #    to_return(:status => 200, :body => Yajl::Encoder.encode(:rooms => @valid_room_cache_data.values), :headers => {})

    #    stub_request(:get, @room_list_url).
    #    with(:headers => {
    #           'Authorization'=>[@valid_params[:api_key], 'X']
    #         }).
    #    to_return(:status => 200, :body => Yajl::Encoder.encode(:rooms => @valid_room_cache_data.values), :headers => {})

    #    # Disable fetch_data_for, not important to this test.
    #    Scamp.any_instance.expects(:fetch_data_for).returns(nil)

    #    Scamp.send(:connect!, [@valid_room_cache_data.keys.first]) do
    #      invoked_cb = true
    #    end
    #  }
    #  invoked_cb.should be_true
    #end

    it "should stream a room"
    it "should handle HTTP errors streaming a room"
    it "should handle network errors streaming a room"
  end

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
