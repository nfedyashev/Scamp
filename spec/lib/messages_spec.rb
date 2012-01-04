#require "spec_helper"
#
#describe Scamp do
#      
#  context "message operations" do
#    before do
#      @valid_params = {:api_key => "6124d98749365e3db2c9e5b27ca04db6", :subdomain => "oxygen"} 
#      Scamp.subdomain = @valid_params[:subdomain]
#      Scamp.api_key   = @valid_params[:api_key]
#
#
#      # Stub fetch for room data
#      @valid_room_cache_data = {
#        123 => {
#          "id" => 123,
#          "name" => "foo",
#          "users" => []
#        },
#        456 => {
#          "id" => 456,
#          "name" => "bar",
#          "users" => []
#        }
#      }
#
#      #@room_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/rooms.json"
#      #@me_list_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/users/me.json"
#      #@room_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/room/123.json"
#      #@stream_url = "https://streaming.campfirenow.com/room/123/live.json"
#
#      @message_post_url = "https://#{@valid_params[:subdomain]}.campfirenow.com/room/123/speak.json"
#    end
#
#    it "should send a message" do
#      #mock_logger
#      
#      EM.run_block {
#        stub_request(:post, @message_post_url).
#          with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).
#          to_return(:status => 201, :body => Yajl::Encoder.encode(:room => @valid_room_cache_data[123]), :headers => {})
#        bot.send(:send_message, 123, "Hi", "Textmessage")
#      }
#      #logger_output.should =~ /DEBUG.*Posted message "Hi" to room 123/
#    end
#
#    it "should paste a message" do
#      #mock_logger
#
#      EM.run_block {
#        stub_request(:post, @message_post_url).
#          with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).
#          to_return(:status => 201, :body => Yajl::Encoder.encode(:room => @valid_room_cache_data[123]), :headers => {})
#        bot.send(:send_message, 123, "Hi", "PasteMessage")
#      }
#      #logger_output.should =~ /DEBUG.*Posted message "Hi" to room 123/
#    end
#
#    it "should handle HTTP errors fetching individual room data" do
#      #mock_logger
#
#      EM.run_block {
#        stub_request(:post, @message_post_url).
#          with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).
#          to_return(:status => 502, :body => "", :headers => {'Content-Type'=>'text/html'})
#        lambda {bot.send(:send_message, 123, "Hi", "Textmessage")}.should_not raise_error
#      }
#      #logger_output.should =~ /ERROR.*Couldn't post message "Hi" to room 123 using url #{@message_post_url}, http response from the API was 502/
#    end
#    
#    it "should handle network errors fetching individual room data" do
#      #mock_logger
#      
#      EM.run_block {
#        stub_request(:post, @message_post_url).
#          with(:headers => {'Authorization'=>[@valid_params[:api_key], 'X'], 'Content-Type' => 'application/json'}).to_timeout
#        lambda {bot.send(:send_message, 123, "Hi", "Textmessage")}.should_not raise_error
#      }
#      #logger_output.should =~ /ERROR.*Couldn't connect to #{@message_post_url} to post message "Hi" to room 123/
#    end
#
#  end
#
#  def mock_logger
#    @logger_string = StringIO.new
#    @fake_logger = Logger.new(@logger_string)
#    Scamp.any_instance.expects(:logger).at_least(1).returns(@fake_logger)
#  end
#
#  # Bleurgh
#  def logger_output
#    str = @logger_string.dup
#    str.rewind
#    str.read
#  end
#end
