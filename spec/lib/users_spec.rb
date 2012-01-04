require "spec_helper"

describe Scamp do
      
  context "user operations" do
    before do
      @valid_params = {:api_key => "6124d98749365e3db2c9e5b27ca04db6", :subdomain => "oxygen"} 
      Scamp.subdomain = @valid_params[:subdomain]
      Scamp.api_key   = @valid_params[:api_key]


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

      #@room_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/rooms.json"
      #@me_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/users/me.json"
      #@room_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/room/123.json"
      #@stream_url = "https://streaming.campfirenow.com/room/123/live.json"
    end
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
