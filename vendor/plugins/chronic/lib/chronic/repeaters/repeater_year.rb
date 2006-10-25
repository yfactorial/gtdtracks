class Chronic::RepeaterYear < Chronic::Repeater #:nodoc:
  
  def next(pointer)
    super
    
    if !@current_year_start
      case pointer
      when :future
        @current_year_start = Time.local(@now.year + 1)
      when :past
        @current_year_start = Time.local(@now.year - 1)
      end
    else
      diff = pointer == :future ? 1 : -1
      @current_year_start = Time.local(@current_year_start.year + diff)
    end
    
    Chronic::Span.new(@current_year_start, Time.local(@current_year_start.year + 1))
  end
  
  def this(pointer = :future)
    super
    
    case pointer
    when :future
      this_year_start = Time.local(@now.year, @now.month, @now.day) + Chronic::RepeaterDay::DAY_SECONDS
      this_year_end = Time.local(@now.year + 1, 1, 1)
    when :past
      this_year_start = Time.local(@now.year, 1, 1)
      this_year_end = Time.local(@now.year, @now.month, @now.day)
    end
    
    Chronic::Span.new(this_year_start, this_year_end)
  end
  
  def offset(span, amount, pointer)
    direction = pointer == :future ? 1 : -1
    
    sb = span.begin
    new_begin = Time.local(sb.year + (amount * direction), sb.month, sb.day, sb.hour, sb.min, sb.sec)
    
    se = span.end
    new_end = Time.local(se.year + (amount * direction), se.month, se.day, se.hour, se.min, se.sec)
    
    Chronic::Span.new(new_begin, new_end)
  end
  
  def width
    (365 * 24 * 60 * 60)
  end
  
  def to_s
    super << '-year'
  end
end