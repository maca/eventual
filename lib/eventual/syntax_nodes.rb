module Eventual
  Weekdays        = %w(domingo lunes martes miércoles jueves viernes sábado).freeze
  MonthNames      = %w(enero febrero marzo abril mayo junio julio agosto septiembre noviembre).unshift(nil).freeze
  ShortMonthNames = %w(ene feb mar abr may jun jul ago sept oct nov dic).freeze
  WdaysR          = [/d/, /l/, /ma/, /mi/, /j/, /v/, /s/].freeze
  WdayListR       = /\b(?:#{ WdaysR.join('|') })/.freeze

  class WdayMatchError < StandardError #:nodoc:
    def initialize value
      @value
    end
    
    def to_s
      "El #{@value.day} de #{MonthNames[@value.month]} del #{@value.year} cae en #{Weekdays[@value.wday]}"
    end
  end

  class Year < Treetop::Runtime::SyntaxNode #:nodoc:
    def value
      match  = text_value.match(/(')?(\d{2,4})/)
      value  = match[2].to_i
      value += 2000 if match[1]
      value
    end
  end

  class WeekdayConstrain < Treetop::Runtime::SyntaxNode #:nodoc:
    def value
      text    = wdays_node.text_value.sub('semana', '')
      days    = text.scan(WdayListR).map{ |d| WdaysR.index /#{d}/ }
      days   += (1..5).map if text.include?('entre')
      days   += [6,0] if text.include?('fines')
      days.uniq
    end
  end

  class MonthName < Treetop::Runtime::SyntaxNode #:nodoc:
    def value
      ShortMonthNames.index(text_value.downcase.match(/#{ ShortMonthNames.join('|') }/).to_s) + 1
    end
  end

  class Node < Treetop::Runtime::SyntaxNode
    attr_accessor :year
    attr_accessor :time_span
    attr_accessor :month
    attr_accessor :weekdays
    attr_accessor :times
    
    # Returns last Date or DateTime of the encompassed period
    def last; to_a.last end
    
    # Returns last Date or DateTime of the encompassed period
    def first; to_a.first end
    
    # Returns an array with all the encompassed Dates or DateTimes
    def to_a; map end
    
    # Returns true if the weekday (as number) correspons to any allowed weekday
    def date_within_weekdays? date
      return true unless weekdays
      weekdays.include? date.wday
    end
    
    # Invokes block once for each Date or DateTime. Creates a new array containing the values returned by the block.
    def map &block
      walk { |elements| elements.map &block }
    end
    
    # Returns true if the Date or DateTime passed is included in the parsed Dates or DateTimes
    def include? date
      result = false
      walk { |elements| break result = true if elements.include? date }
      
      return result if !result or date.class == Date or times.nil?
      
      case times
      when Range
        (times.first.to_i..times.last.to_i).include? date.strftime("%H%M").to_i
      else
        times.map{ |time| time.to_i }.include? date.strftime("%H%M").to_i
      end
    end
    
    private
    def walk &block
      year  = self.year || Date.today.year
      month = nil
          
      walk  = lambda do |elements|
        break unless elements
        weekdays = elements.shift.value if WeekdayConstrain === elements.first
        
        elements.reverse.map do |element|
          case element
          when Day, Period
            element.weekdays = weekdays
            element.year     = year
            element.month    = month
            element.times    = @times
            yield element
          when Year
            year  = element.value
            next nil
          when MonthName
            month = element.value
            next nil
          when Times
            @times = element.map
            next nil
          when TimeRange
            @times = element.value
            next nil
          else            
            walk.call element.elements
          end
        end.reverse
      end
      walk.call(elements).flatten.compact
    end
  
    def make year, month, day
      case times
      when nil
        Date.civil year, month, day
      when Range
        first = DateTime.civil year, month, day, times.first.hour, times.first.minute
        last  = DateTime.civil year, month, day, times.last.hour,  times.last.minute
        (first..last)
      else
        times.map do |time| 
          DateTime.civil year, month, day, time.hour, time.minute
        end
      end
    end
  end

  class Day < Node #:nodoc:
    def value
      Date.civil year, month, text_value.to_i
    end
    
    def map &block
      dates = make(year, month, text_value.to_i)
      dates = [dates] unless Array === dates
      raise WdayMatchError.new(dates.first) unless date_within_weekdays? dates.first
      dates.map &block
    end
    
    def include? date
      map { |element| [*element].map{ |e| e.strftime("%Y-%m-%d") } }.flatten.include? date.strftime("%Y-%m-%d")
    end
  end

  class Period < Node #:nodoc:
    def range
      (first..last)
    end
    
    def include? date
      return false unless date_within_weekdays? date
      range.include? date
    end
    
    alias node_map map
    private :node_map
    
    def map &block
      range.map do |date|
        next unless date_within_weekdays? date
        dates = times ? make(date.year, date.month, date.day) : [date]
        dates.map &block
      end
    end
  end

  class MonthPeriod < Period #:nodoc:
    def first
      Date.civil year, month_name.value
    end

    def last
      Date.civil year, month_name.value, -1
    end
  end

  class DatePeriod < Period #:nodoc:
    def first
      node_map.first
    end
    
    def last
      node_map.last
    end
  end

  class Times < Treetop::Runtime::SyntaxNode #:nodoc:
    def map
      walk_times = lambda do |elements|
        break unless elements
        elements.map { |e| Time === e ? e.value : walk_times.call(e.elements) }
      end
      walk_times.call(elements).flatten.compact.sort_by{ |t| '%02d%02d' % [t.hour, t.minute] }
    end
  end

  class Time < Treetop::Runtime::SyntaxNode #:nodoc:
    attr_accessor :hour, :minute
    def value
      @hour, @minute = text_value.scan(/\d+/).map(&:to_i)
      @minute ||= 0
      self
    end
    
    def to_i
      ("%02d%02d" % [@hour, @minute]).to_i
    end
  end

  class Time12 < Time #:nodoc:
    def value
      super
      @hour += 12 if period.text_value.gsub(/[^a-z]/, '') == 'pm'
      self
    end
  end

  class TimeRange < Node #:nodoc:
    def value
      (first.value..last.value)
    end
  end
end