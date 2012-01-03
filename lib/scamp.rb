require 'eventmachine'
require 'em-http-request'
require 'yajl'
require "logger"

require "scamp/version"
require 'scamp/connectable'
require 'scamp/room'
require 'scamp/room_repository'
require 'scamp/user'
require 'scamp/user_repository'
require 'scamp/expectation'
require 'scamp/action'
require 'scamp/message'
require 'scamp/api'
require 'scamp/configurable'

require 'pry'

class Scamp
  include Connectable
  include Configurable

  attr_accessor :rooms, :user_cache, :room_cache, :expectations, :logger, :ignore_self, :required_prefix, :rooms_to_join

  def initialize(options = {})
    configure(options || {})

    @rooms_to_join = []
    @rooms = {}
    @user_cache = {}
    @room_cache = {}
    @expectations ||= []
  end
  
  def behaviour &block
    instance_eval &block
  end
  
  #def command_list
  #  matchers.map{|m| [m.trigger, m.conditions] }
  #end

  private

  def match(expectation, params={}, &block)
    options = {:action => block, :conditions => params[:conditions], :required_prefix => required_prefix}
    expectations << Expectation.new(expectation, options)
  end

  def process_message(msg)
    logger.debug "Received message #{msg.inspect}"

    expectations.each do |expectation|
      expectation.check(Message.make(msg))

      break if ::Scamp::first_match_only
    end
  end
end
