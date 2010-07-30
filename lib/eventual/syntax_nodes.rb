module Eventual
  Weekdays        = %w(domingo lunes martes miércoles jueves viernes sábado).freeze
  MonthNames      = %w(enero febrero marzo abril mayo junio julio agosto septiembre noviembre).unshift(nil).freeze
  ShortMonthNames = %w(ene feb mar abr may jun jul ago sept oct nov dic).freeze
  WdaysR          = [/d/, /l/, /ma/, /mi/, /j/, /v/, /s/].freeze
  WdayListR       = /\b(?:#{ WdaysR.join('|') })/.freeze

  class WdayMatchError < StandardError #:nodoc:
    def initialize value, wday_index
      @value, @wday_index = value, wday_index
    end
    
    def to_s
      "El #{@value.day} de #{MonthNames[@value.month]} del #{@value.year} cae en #{Weekdays[@value.wday]} no #{Weekdays[@wday_index]}"
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
    def last
      to_a.last
    end
    
    # Returns last Date or DateTime of the encompassed period
    def first
      to_a.first
    end
    
    # Returns an array with all the encompassed Dates or DateTimes
    def to_a
      map
    end
    
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
      
      unless date.class == Date or times.nil? or times.empty?
        @time_span  ||= 60
        return false unless times.inject(nil){ |memo, time|
          check_against = ::Time.local date.year, date.month, date.day, time.hour, time.minute
          time          = ::Time.local date.year, date.month, date.day, date.hour, date.min
          break true if time >= check_against && time < check_against + 60 * @time_span
        }
      end
      result
    end
    
    private
    def walk &block
      year  = self.year || Date.today.year
      month = nil
          
      walk  = lambda do |elements|
        break unless elements
        weekdays = elements.first.value if elements.first.class == WeekdayConstrain
        
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
          when WeekdayConstrain
            next nil
          when Times
            @times = element.map
            next nil
          else
            walk.call element.elements
          end
        end.reverse
      end
      walk.call(elements).flatten.compact
    end
  end

  class Day < Node #:nodoc:
    def map &block
      dates = times ? times.map{ |time| DateTime.civil year, month, text_value.to_i, time.hour, time.minute } : [Date.civil(year, month, text_value.to_i)]
      raise WdayMatchError.new(dates.first, weekdays.first) unless date_within_weekdays? dates.first
      dates.map(&block)
    end
    
    def include? date
      map{ |e| e.strftime("%Y-%m-%d") }.include? date.strftime("%Y-%m-%d")
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
    
    def map
      array = []
      range.each do |date|
        next unless date_within_weekdays? date
        next array.push(block_given? ? yield(date) : date) unless times
        
        times.each do |time|
          new_date = DateTime.civil date.year, date.month, date.day, time.hour, time.minute
          array.push block_given? ? yield(new_date) : new_date
        end
      end
      array
    end
  end

  class MonthPeriod < Period #:nodoc:
    def first
      return Date.civil(year, month_name.value) unless times and !times.empty?
      time = times.first
      return DateTime.civil(year, month_name.value, 1, time.hour, time.minute)
    end
    
    def last
      date = (first >> 1) - 1
      return date unless times and !times.empty?
      time = times.last
      DateTime.civil(date.year, date.month, date.day, time.hour, time.minute)
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
    

  end

  class Time12 < Time #:nodoc:
    def value
      super
      @hour += 12 if period.text_value.gsub(/[^a-z]/, '') == 'pm'
      self
    end
  end
end