module Xplain::RDF
  module RelationMapper
    
    attr_accessor :limit, :offset
    
    def self.included klass
       klass.class_eval do
         include SPARQLHelper
       end
    end
  
  
    def image(relation, offset = 0, limit = -1, crossed=false, &block)
      items = []
      values_stmt = ""
      if relation.inverse? && !crossed
        return domain(relation, offset, limit, true, &block)
      end
          
      query_stmt = "SELECT distinct ?o where{#{values_stmt} ?s <#{Xplain::Namespace.expand_uri(relation.id)}> ?o}"
      query_stmt = insert_order_by_subject(query_stmt)
      
      if limit > 0
        query_stmt << " OFFSET #{offset} LIMIT #{limit}"
      end
      
      get_results(query_stmt, relation)
    end
  
    def domain(relation, offset=0, limit=-1, crossed=false, &block)
      items = []
      values_stmt = ""
      if relation.inverse? && !crossed
        return image(relation, offset, limit, true, &block) 
      end
      query_stmt = "SELECT ?s ?o where{#{values_stmt} #{path_clause(relation)} #{path_clause_as_subselect(relation, values_stmt, "?s", limit, offset)}.}"
      query_stmt = insert_order_by_subject(query_stmt)
      
      
      get_results(query_stmt, relation)
    end
  
    def restricted_image(args)
      restriction_items = args[:restriction].map{|node|node.item} || [] 
      relation = args[:relation] || nil
      image_filter_items = args[:image_filter] || []
      
      results_hash = {}      
      where_clause = ""
      relation_uri = parse_relation(relation)
      
      paginate(restriction_items, @items_limit).each do |page_items|
        
        if(relation.is_a?(Xplain::PathRelation) && relation.size > 1)
    
          where_clause = "{#{path_clause(relation)}}. #{values_clause("?s", page_items)} #{values_clause("?o", image_filter_items)} #{mount_label_clause("?o", page_items, relation)}"
        else
          where_clause = "#{values_clause("?s", page_items)} {#{path_clause(relation)}}. #{mount_label_clause("?o", page_items, relation)} #{values_clause("?o", image_filter_items)}"
        end
        
        query = "SELECT ?s ?o ?lo "
        if args[:group_by_domain]
          query << " ?ls "
          where_clause << " #{mount_label_clause("?s", page_items)}"
        end
        query << " where{#{where_clause} }"
        query = insert_order_by_subject(query)
      
        results_hash.merge! get_results(query, relation)
        
      end
  
      results_hash
    end
  
    def restricted_domain(args)
      restriction_items = args[:restriction].map{|node|node.item} || [] 
      relation = args[:relation] || nil
      
      domain_items = args[:domain_filter] || []
      results_hash = {}
      
      paginate(restriction_items, @items_limit).each do |page_items|
      
        label_clause = mount_label_clause("?s", page_items, relation)
    
        where = "#{path_clause(relation)}. #{label_clause}"
        if(!domain_items.empty?)
          where = "#{values_clause("?s", domain_items)}" << where
        end
    
        query = "SELECT ?s ?o ?ls WHERE{#{where}  #{values_clause("?o", page_items)} #{path_clause_as_subselect(relation, values_clause("?o", page_items) + values_clause("?s", domain_items), "?s", args[:limit], args[:offset])}}"
        query = insert_order_by_subject(query)
        
        results_hash.merge! get_results(query, relation)      
      end
      results_hash
    end
  
      
    def find_relations(items)
      results = Set.new
      paginate(items, @items_limit).each do |page_items|
        are_literals = !page_items.empty? && page_items[0].is_a?(Xplain::Literal)    
        if(are_literals)
          query = "SELECT distinct ?pf WHERE{ {VALUES ?o {#{page_items.map{|i| convert_literal(i.item)}.join(" ")}}. ?s ?pf ?o.}}"
        else
          query = "SELECT distinct ?pf ?pb WHERE{ {VALUES ?o {#{page_items.map{|i| "<" + i.item.id + ">"}.join(" ")}}. ?s ?pf ?o.} UNION {VALUES ?s {#{page_items.map{|i| "<" + i.item.id + ">"}.join(" ")}}. ?s ?pb ?o.}}"
        end
        
        execute(query).each do |s|
          if(!s[:pf].nil?)
            results << Xplain::SchemaRelation.new(Xplain::Namespace.colapse_uri(s[:pf].to_s), true, self)
          end
          
          if(!s[:pb].nil?)
            results << Xplain::SchemaRelation.new(Xplain::Namespace.colapse_uri(s[:pb].to_s), false, self)
          end
        end
      end
      results.sort{|r1, r2| r1.to_s <=> r2.to_s}
      
    end
    
    ###
    ### Meta relation handler methods
    ###
    
    def relations_image(options = {}, &block)
      query = "SELECT DISTINCT ?p WHERE { ?s ?p ?o.}"
      relations = []
      execute(query, options).each do |s|
        relation = Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(s[:p].to_s), server: self)      
        relations << relation
      end
      relations
    end
    
    ##TODO implement
    def relations_domain(options = {}, &block)
      []
    end
  
    def has_type_image(options= {} &block)
      
      query = "SELECT DISTINCT ?class WHERE { ?s a ?class.}"
      classes = []
      execute(query, options).each do |s|
        type = Xplain::Type.new(Xplain::Namespace.colapse_uri(s[:class].to_s))
        type.add_server(self)
        classes << type
      end
      classes
    end
    
      
    def relations_restricted_image(args)
      
      restriction_items = args[:restriction].map{|node|node.item} || []
      results = Set.new
      are_literals = !restriction_items.empty? && restriction_items[0].is_a?(Xplain::Literal)
      paginate(restriction_items, @items_limit).each do |page_items|
        if(are_literals)
          query = "SELECT distinct ?pf WHERE{ {#{values_clause("?o", page_items)}}. ?s ?pf ?o.}"
        else
          query = "SELECT distinct ?pf ?pb WHERE{ {{#{values_clause("?o", page_items)}}. ?s ?pf ?o.} UNION {{#{values_clause("?s", page_items)}}. ?s ?pb ?o.}}"
        end
      
        execute(query).each do |s|
          if(!s[:pf].nil?)
            results << Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(s[:pf].to_s), inverse: true)
          end
          
          if(!s[:pb].nil?)
            results << Xplain::SchemaRelation.new(id: Xplain::Namespace.colapse_uri(s[:pb].to_s), inverse: false)
          end
        end
      end
      
      results.sort{|r1, r2| r1.to_s <=> r2.to_s}
    end
    
    ##TODO implement
    def relations_restricted_domain(args)
      
      restriction_items = args[:restriction].map{|node|node.item} || []
      entities = []
      paginate(restriction_items, @items_limit).each do |page_items|
        query = "SELECT DISTINCT ?s WHERE { #{values_clause("?relation", page_items)} ?s ?relation ?o. }"
        
        execute(query).each do |s|
          entity = Xplain::Entity.new(Xplain::Namespace.colapse_uri(s[:s].to_s))
          # relation.text = s[:label].to_s if !s[:label].to_s.empty?
          entity.server = self
          entities << entity
        end
      end
      entities
    end
    
    def has_type_restricted_image(args)
      restriction_items = args[:restriction].map{|node|node.item} || []
      classes = []
      paginate(restriction_items, @items_limit).each do |page_items|
        query = "SELECT DISTINCT ?class WHERE {#{values_clause("?s", page_items)} ?s a ?class.}"
      
        execute(query).each do |s|
          type = Xplain::Type.new(Xplain::Namespace.colapse_uri(s[:class].to_s))
          type.add_server(self)
          classes << type
        end
      end
      
      classes.sort{|r1, r2| r1.to_s <=> r2.to_s}
  
    end  
    
    def has_type_restricted_domain(args)
      restriction_items = args[:restriction].map{|node|node.item} || []
      
      entities = []
      paginate(restriction_items, @items_limit).each do |page_items|
        query = "SELECT DISTINCT ?s WHERE {#{values_clause("?class", page_items)} ?s a ?class.}"
        execute(query).each do |s|
          entity = Xplain::Entity.new(Xplain::Namespace.colapse_uri(s[:s].to_s))
          entity.add_server(self)
          entities << entity
        end
      end
      entities.sort{|r1, r2| r1.to_s <=> r2.to_s}
    end
    
  end
end

