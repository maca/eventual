$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'rspec'
require 'rspec/autorun'

class MapDates
  def description
    "map times"
  end
  
  def initialize expected, klass
    @klass = klass
    @expected = expected.map(&:to_s).sort
  end
  
  def matches? actual
    @actual =  actual.map{ |d| d.to_s }
    @actual == @expected
  end
  
  def failure_message
    "expected #{ @expected.inspect }, got #{ @actual.inspect }"
  end
end

def map_times *times
  MapDates.new times, DateTime
end

def map_dates *times
  MapDates.new times, Date
end
