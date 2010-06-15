require 'treetop'
require 'date'

require "#{ File.dirname __FILE__ }/syntax_nodes"
require "#{ File.dirname __FILE__ }/es/event_parser"

module Eventual
  module Es; end
  Es.const_set 'EventParser', Module.const_get('EventParser')
  Object.send :remove_const, 'EventParser'
end