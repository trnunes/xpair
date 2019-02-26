module Xplain
  #TODO implement a save method tracking updates and also result-set updates
  class Session
    include Xplain::SessionWritable
    include Xplain::SessionReadable
    
    attr_accessor :id, :title, :result_sets
    
    def initialize(session_id, title=nil)
      @id = session_id
      @title = title
      @title ||= session_id.gsub("_", " ")
      @result_sets = []
    end
    
    def <<(result_set)
      
      resulted_from_array = [result_set]
      #TODO Keep cached in memory
      while !resulted_from_array.empty?
        resulted_from_array.each do |r_from|
          
          add_result_set(r_from)
          
        end
        resulted_from_array = resulted_from_array.map{|r| r.resulted_from}.flatten(1)
      end
    end
    
    def empty?
      Xplain::ResultSet.find_by_session(self).empty?
    end
    
    def each_result_set_tsorted(options={}, &block)
      iterable = @result_sets
      if @result_sets.empty?
        @result_sets = Xplain::ResultSet.find_by_session(self, options)
        iterable = @result_sets
      else
        if options[:exploration_only]
          iterable = @result_sets.select{|s| !s.intention.visual?}
        end
      end
      
      Xplain::ResultSet.topological_sort(iterable).each &block
      
    end
    
  end
end