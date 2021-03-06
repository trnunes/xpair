module Xplain
  #TODO implement a save method tracking updates and also result-set updates
  class Session
    include Xplain::SessionWritable
    include Xplain::SessionReadable
    
    attr_accessor :id, :title, :result_sets, :server
    
    def initialize(session_id, title=nil)
      @id = session_id
      @title = title
      @title ||= session_id.gsub("_", " ")
      @result_sets_hash = {}
      @server = Xplain.default_server
    end
    
    def set_server(params)
      if params.is_a? Hash
        klass = params[:class]
        klass = eval(klass) if klass.is_a? String
        begin
          @server = klass.new(params)
        rescue RepositoryConnectionError => e
          raise RepositoryConnectionError.new("Session repository connection error: " << e.message)
        end
      else
        @server = params
      end
      
    end
    
    def clear_cache_by_intention_slice(intention_slice)
       keys = @result_sets_hash.keys.select{|i| i.include?(intention_slice.gsub(" ", ""))}
       keys.each{|key| @result_sets_hash.delete(key)}
    end

    def cache
      @result_sets_hash
    end

    def <<(result_set)
      @result_sets_hash[result_set.intention.to_ruby_dsl_sum] = result_set
      add_result_set(result_set)
    end
    
    def execute(operation)
      cached_rs = @result_sets_hash[operation.to_ruby_dsl_sum]
      puts "--------------EXECUTING IN SESSION---------"
      puts DSLParser.new.to_ruby(operation)
      if cached_rs
        return cached_rs
      end
      
      input_resultsets = operation.inputs.map do |input|
        input_intention = nil        
        if input.is_a? Xplain::Operation
          input_intention = input
        else
          input_intention = input.intention
        end
        
        cached_input = @result_sets_hash[input_intention.to_ruby_dsl_sum]
        cached_input || self.execute(input_intention)
      end
      operation.inputs = input_resultsets
      operation.server = @server
      rs = operation.execute
      @result_sets_hash[operation.to_ruby_dsl_sum] = rs
      rs.save
      
      self << rs
      rs
    end
    
    def find_leaves
      result_sets = @result_sets_hash.values
      result_sets.select do |rs1|
        result_sets.select do |rs2|
          rs2.intention.inputs.include?(rs1)
        end.empty?
      end
    end
    
    def copy_graph(result_set, copied_sets_hash = {} )
      
      copied_inputs = result_set.intention.inputs.map{|input| copy_graph(input, copied_sets_hash)[input]}
      return copied_sets_hash if copied_sets_hash.has_key? result_set
      copied_set = result_set.copy
      copied_set.intention.inputs = copied_inputs
      copied_set.save
      copied_sets_hash[result_set] = copied_set
      copied_sets_hash
    end
    
    def deep_copy
      copied_session = Session.create(title: @title.dup)
      copied_session.server = @server
      result_sets = @result_sets_hash.values
      leaves = find_leaves
      copied_sets_hash = {}
      
      leaves.each{|leaf| copy_graph(leaf, copied_sets_hash) }
      copied_sets_hash.values.each{|r| copied_session << r}
      copied_session
    end
    
    def add_graph(leaves)
      
    end
    
    def eval_graph(graph_nodes)
      ordered_resultsets = Xplain::ResultSet.topological_sort(graph_nodes)
      
      ordered_resultsets.each do |rs| 
        rs.intention.server = @server
        rs.fetch 
        @result_sets_hash[rs.intention.to_ruby_dsl_sum] = rs
      end
    end
    
    
    def each_result_set_tsorted(options={}, &block)
      
      if @result_sets_hash.empty?
        result_sets = Xplain::ResultSet.find_by_session(self, options)
        self.eval_graph(result_sets)
      end
      result_sets = @result_sets_hash.values
      if options[:exploration_only]
        result_sets.select!{|s| !s.intention.visual?}
      end
      result_sets = Xplain::ResultSet.topological_sort(result_sets)
      result_sets.each &block
    end
    
  end
end