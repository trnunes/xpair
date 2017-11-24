module SPARQLHelper
  
  def convert_literal(literal)
    if literal.datatype
      "\"#{literal.value.to_s}\"^^#{get_literal_type(literal)}"
    else
      if literal.value.to_s.match(/\A[-+]?[0-9]+\z/).nil?
        "\"" + literal.value.to_s + "\""
      else
        if literal.value.to_f.to_s == literal.value.to_s
          literal.value.to_s.to_f
        elsif literal.value.to_s.to_i.to_s == literal.value.to_s
          literal.value.to_s.to_i
        end
      end
    end
  end
  
  def convert_item(item)
    "<#{Xplain::Namespace.expand_uri(item.id)}>"
  end
  
  def convert_path_relation(relation)
    relation.map{|r| "<" + Xplain::Namespace.expand_uri(r.to_s) + ">"}.join("/")
  end
  
  def parse_item(item)

    if(item.is_a? Xplain::Literal)
      convert_literal(item)
    elsif(item.is_a? Xplain::PathRelation)
      convert_path_relation(item)      
    elsif(item.is_a?(Xplain::Entity) || item.is_a?(Xplain::Relation))
      convert_item(item)
    else
      item.to_s
    end
  end
  
  #TODO improve to generate paths with mmultiple-direction relations
  def path_clause(relations, obj_var = "?o")
    query = 
    if accept_path_clause?
      relations.map{|r| "<" + Xplain::Namespace.expand_uri(r.to_s) + ">"}.join("/")
    elsif relations.is_a?(Xplain::SchemaRelation)
      if(relations.inverse?)
        clause = "#{obj_var} <" + Xplain::Namespace.expand_uri(relations.id) + "> ?s"
      else
        clause = "?s <" + Xplain::Namespace.expand_uri(relations.id) + "> #{obj_var}"
      end
      
    else
      count = 0
      svar = "?s"
      
      if relations.size == 1
        if relations.first.inverse?
          return "#{obj_var} <" + Xplain::Namespace.expand_uri(relations.id) + "> ?s"
        else
          return "?s <" + Xplain::Namespace.expand_uri(relations.id) + "> #{obj_var}"
        end
      else
        ovar = "?s1"
      end
      
      relations.map do |r|           
        count += 1
        ovar = obj_var if (count == relations.size)
        if(r.inverse?)
          clause = "#{ovar} <" + Xplain::Namespace.expand_uri(r.id) + "> #{svar}"
        else
          clause = "#{svar} <" + Xplain::Namespace.expand_uri(r.id) + "> #{ovar}"
        end
        svar = ovar
        ovar = "?s#{count}"
        clause
      end.join(".")      
    end
    # binding.pry
    query
  end
  
  def path_clause_as_subselect(relations, values_clause_stmt="", select_var = "?o", limit=0, offset = 0)
    query = "SELECT distinct #{select_var}{#{values_clause_stmt} #{path_clause(relations)}}"
    "{" + insert_limit_clause(query, limit, offset) + "}"
  end
  
  def insert_limit_clause(query, limit, offset = 0)
    if limit.to_i > 0
      query << " LIMIT #{limit} OFFSET #{offset}"
    end
    query
  end
  
  def insert_order_by_subject(query)
    query << " ORDER BY ?s"
    query
  end

  def label_where_clause(var, label_relations)
    return "" if label_relations.empty?

    label_relations.map do |l|
      expanded_uri = Xplain::Namespace.expand_uri(l)
      if var == "?s"
        "{" + var + " <#{expanded_uri}> " + "?ls" + "}."
      else
        "{" + var + " <#{expanded_uri}> " + "?lo" + "}."
      end
      
    end.join(" OPTIONAL")
  end
  
  def values_clause(var, iterable)
    values_clause = ""
    if iterable.size > 0
      values_clause = "VALUES #{var}{" << iterable.each.map{|item| parse_item(item)}.join(" ") << "}."
    end

    values_clause
  end
  
  def mount_label_clause(var, items, relation)
    
    relation_uri = parse_item(relation)
     
    label_clause = ""
    label_relations = []
    if relation.inverse?
      label_relations = Xplain::Visualization.domain_label_relations(relation)
    else

      label_relations = Xplain::Visualization.image_label_relations(relation)
    end
    
    if !label_relations.empty?
      label_clause = label_where_clause(var, label_relations)
    else
      type = sample_type(relation_uri, items, relation.inverse?)
      label_clause = label_where_clause(var, Xplain::Visualization.label_relations_for(type))
    end

    label_clause = "OPTIONAL " + label_clause if !label_clause.empty?
    label_clause
  end
  
  def build_literal(literal)
    xplain_literal = 
    if (literal.respond_to?(:datatype) && !literal.datatype.to_s.empty?)
      Xplain::Literal.new(literal.to_s, literal.datatype.to_s)
    else
      if literal.to_s.match(/\A[-+]?[0-9]+\z/).nil?
        Xplain::Literal.new(literal.to_s)
      else
        Xplain::Literal.new(literal.to_s.to_i)
      end
    end
    if xplain_literal.value.to_s.to_i.to_s == xplain_literal.value.to_s
      xplain_literal.value = xplain_literal.value.to_s.to_i
    end
    if xplain_literal.value.to_f.to_s == xplain_literal.value.to_s
      xplain_literal.value = xplain_literal.value.to_s.to_f
    end
    # binding.pry
    xplain_literal
  end
  
  def get_literal_type(literal)
    datatype = literal.datatype
    case datatype
      when "http://www.w3.org/2001/XMLSchema#nonPositiveInteger"
        "xsd:integer"
      when "http://www.w3.org/2001/XMLSchema#negativeInteger"
        "xsd:integer"
      when "http://www.w3.org/2001/XMLSchema#long"
        "xsd:integer"
      when "http://www.w3.org/2001/XMLSchema#int"
        "xsd:integer"
      when "http://www.w3.org/2001/XMLSchema#short"
        "xsd:integer"
      when "http://www.w3.org/2001/XMLSchema#double"
        "xsd:double"
      when "http://www.w3.org/2001/XMLSchema#float"
        "xsd:float" 
      when "http://www.w3.org/2001/XMLSchema#date"
        "xsd:date"
      when "http://www.w3.org/2001/XMLSchema#datetime"
        "xsd:datetime"
      else
        "xsd:string"
    end
  end
  
  
  def get_filter_results(query)
    items = []
    execute(query).each do |solution|
      next if(solution.to_a.empty?)
      subject_id = Xplain::Namespace.colapse_uri(solution[:s].to_s)
      items << Node.new(Xplain::Entity.new(subject_id))
    end
    items
  end
  
  def get_results(query, relation)
    root = Node.new(relation)
    
    domain_hash = {}
    
    execute(query).each do |solution|
      next if(solution.to_a.empty?)
      subject_id = Xplain::Namespace.colapse_uri(solution[:s].to_s)
      if(!domain_hash.has_key? subject_id)
        item = Xplain::Entity.new(subject_id)
        item.text = solution[:ls].to_s
        item.add_server(@server)
        item_node = Node.new(item)
        domain_hash[subject_id] = item_node
      end
      item_node = domain_hash[subject_id]
      root.children_edges << Edge.new(root, item_node)
      item_node.parent_edge = Edge.new(root, item_node)
      
      triple_object = solution[:o]
      
      if(triple_object)
        if(triple_object.literal?)
          related_item = build_literal(triple_object)
        else
          related_item = Xplain::Entity.new(Xplain::Namespace.colapse_uri(triple_object.to_s))
          related_item.type = "rdfs:Resource"
          related_item.add_server @server
        end
        related_item_node = Node.new(related_item)
        item_node.children_edges << Edge.new(item_node, related_item_node)
        related_item_node.parent_edge = Edge.new(item_node, related_item_node)
      end
    end

    root.children
  end
  
    #version 1: returns a hash of the results
  # def get_results(query, relation)
  #   hash = {}
  #
  #   execute(query).each do |solution|
  #
  #
  #     subject_id = Xplain::Namespace.colapse_uri(solution[:s].to_s)
  #     if(solution[:p].nil?)
  #       if(relation.is_a?(Array))
  #         relation_id = relation.map{|r| r.to_s}.join("/")
  #       else
  #         relation_id = relation.to_s
  #       end
  #     else
  #       relation_id = Xplain::Namespace.colapse_uri(solution[:p].to_s)
  #     end
  #     item = Entity.new(subject_id)
  #     item.text = solution[:ls].to_s
  #     item.add_server(@server)
  #     relation = SchemaRelation.new(id: relation_id, server: @server)
  #
  #
  #     hash[item] ||= {}
  #     hash[item][relation] ||=[]
  #
  #     if(solution[:o])
  #       if solution[:o].literal?
  #         object = build_literal(solution[:o])
  #       else
  #         object = Entity.new(Xplain::Namespace.colapse_uri(solution[:o].to_s))
  #         object.type = "rdfs:Resource"
  #         object.text = solution[:lo].to_s
  #         object.add_server(@server)
  #       end
  #       hash[item][relation] << object
  #     end
  #
  #   end
  #   hash
  # end
  
  
end