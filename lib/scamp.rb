$:.unshift File.expand_path(File.dirname(__FILE__) + '/scamp')

require 'tinder'
require 'repository'
require 'active_support/core_ext/class'

require 'pry'

require 'configurable'
require 'connectable'
require "version"
require 'room'
require 'user'
require 'expectation'
require 'action'
require 'message'

class Scamp
  include Configurable
  include Connectable

  def initialize(options = {})
    configure(options || {})

    @expectations ||= []
  end

  def behaviour &block
    instance_eval &block
  end

  def process_message
    @process_message ||= lambda do |msg|
      #TODO - explain type check
      break unless msg['type'] == 'TextMessage'

      logger.debug "Received message #{msg.inspect}"

      @expectations.each do |expectation|
        expectation.check(Message.make(msg))

        break if ::Scamp::first_match_only
      end
    end
  end
  
  #def command_list
  #  matchers.map{|m| [m.trigger, m.conditions] }
  #end

  def match(expectation, params={}, &block)
    options = {:action => block, :conditions => params[:conditions], :required_prefix => required_prefix}
    @expectations << Expectation.new(expectation, options)
  end
end
