require 'treetop'
require 'date'

require "#{ dir = File.dirname __FILE__ }/eventual/syntax_nodes"
Treetop.load "#{dir}/eventual/es"

module Eventual
  @parser = EsParser.new
  
  def self.parse string
    @parser.parse string
  end
end