
module Filtering
  class Equals < Filtering::Filter
    def initialize(*args)
      super(args)
      
      if args.size == 1
        @value = args[0]
      elsif args.size == 2
        @relations = args[0]
        @value = args[1]
      else
        raise "Invalid number of arguments. Expected: min 1, max 2; Received: #{args.size}"
      end      
    end
    
    def eval(set)
      extension = set.extension_copy
      if(@relations.nil?)
          set.each.select{|item| !(item.eql?(@value))}.each do |removed_item|
            extension.delete(removed_item)
          end
      else        
        build_query_filter(set).relation_equals(@relations, @value)        
      end
      super(extension, set)
    end
    
    def expression
      if(@relations.nil?)
        ".equals(\"#{@value.to_s}\")"
      else
        ".equals(\"#{@relations.to_s}\", \"#{@value.to_s}\")"
      end
    end  
  end
  
  def self.equals(args)
    if args[:values].nil?
      raise "MISSING VALUES FOR FILTER!"
    end
    self.add_filter(Equals.new(args[:relations], args[:values]))
    self
  end
end