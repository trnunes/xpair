module Xplain
  class ResultSet < Node
    extend Forwardable
    include Xplain::ResultSetWritable
    extend Xplain::ResultSetReadable
    include Xplain::DslCallable
    include Xplain::Relation
    
    attr_accessor :intention, :inverse, :title
    def_delegators :children, :each, :map, :select, :empty?, :size, :uniq, :sort
    
    def initialize(params = {})
      super(params)
      nodes_list = params[:nodes] || []
      input_is_list_of_items = !nodes_list.first.is_a?(Xplain::Node)
      
      self.children = 
        if input_is_list_of_items
          nodes_list.map{|item| Xplain::Node.new(item: item)}          
        else
          nodes_list
        end
      @intention = params[:intention]
      @inverse = params[:inverse]
      @title = params[:title] || "Set #{Xplain::ResultSet.count + 1}"
    end
    
    def nodes
      self.children
    end
        
    def inverse?
      @inverse
    end
        
    def resulted_from
      inputs = []
      if @intention && !@intention.is_a?(String)
        inputs = @intention.inputs
      end
      inputs || []
    end
    
    
    def history
      history_sets = []
      if !resulted_from.empty?
        history_sets += resulted_from.map{|rs| rs.history}.flatten(1)
        history_sets += resulted_from
      end
      
      history_sets
    end
    
    def copy
      copied_root = super
      copied_root.children.each{|c| c.parent_edges = []}
      #TODO Correct the "id" parameter. They cannot be the same!
      Xplain::ResultSet.new(id: self.id, nodes: copied_root.children, intention: @intention, title: @title.dup, notes: @annotations.dup, inverse: @inverse)
    end
    
    def get_page(total_items_by_page, page_number)
      if self.children.is_a? Set
        self.children = self.children.to_a
      end
      pg_offset = 0
      
      total_of_pages = count_pages(total_items_by_page)
      page_nodes = []
      limit = total_items_by_page
      if total_items_by_page > self.size
        limit = self.size
      end
      if (page_number > 0)
        pg_offset = (page_number - 1) * total_items_by_page
        page_nodes = self.children[pg_offset..(pg_offset + limit - 1)]
      end
      page_nodes
    end
    
    
    ###
    ### TODO accelerate this method by calling children only the first time 
    ###
    def [](index)
      children[index]
    end
    
    
    def contain_literals?
      children.to_a[0].is_a? Xplain::Literal
    end
    
    def include_node?(node_id)
      !breadth_first_search(false){|node| node.id == node_id}.empty?
    end
   
   #TODO find a better place for uniq and sort operations
    def uniq
      items_hash = {}
      children.each do |node|
        #TODO IMPLEMENT A SHALLOW CLONE METHOD
        items_hash[node.item] = Xplain::Node.new item: node.item
      end
      Xplain::ResultSet.new(nodes: items_hash.values)
    end
    
    def uniq!
      items_hash = {}
      children.each do |node|        
        items_hash[node.item] = node
      end

      self.children = items_hash.values
      self
    end
    
    def sort(desc=true)
      Xplain::ResultSet.new(nodes: children.sort do|n1, n2|
        comparator = 
          if (n1.item.is_a?(Xplain::Literal) && n2.item.is_a?(Xplain::Literal) && n1.item.numeric? && n2.item.numeric?)
             
            n1.item.value.to_f <=> n2.item.value.to_f
          else
            n1.item.text <=> n2.item.text
          end
        if desc
          -comparator
        else
          comparator 
        end
        
      end)
      
    end
    
    def sort_asc
      rs = sort(false)
      rs
      
    end
    
    def sort!
      self.children = self.sort.nodes
      self
    end
    
    def sort_asc!
      self.children = self.sort_asc.nodes
      self
    end
    
    def count_pages(total_by_page)
      if total_by_page == 0
        return 0
      end
    
      (size.to_f/total_by_page.to_f).ceil
    end
    
    def inspect()
      self.children.inject{|concat_string, node| concat_string.to_s + ", #{node.item.text}"}
    end
    
#### RELATION OPERATIONS ######
    def restricted_image(restriction, options={})
      #TODO implement the group_by_domain option!
      
      restriction_items = Set.new(
        restriction.map do |res_item|
          if res_item.respond_to? :item
            res_item.item  
          else
            res_item
          end
        end
      )
      #TODO implement the group_by_domain option!
      image = self.children.select{|node| restriction_items.include? node.item}.map{|node| node.children}.flatten.compact
      Xplain::ResultSet.new(nodes: image)
    end
  
    def restricted_domain(restriction, options={})
      #TODO implement the group_by_domain option!
      items_set = Set.new(restriction.map{|node| node.item})
      intersected_image = children.map{|dnode| dnode.children}.flatten.select{|img_node| items_set.include? img_node.item}
      Xplain::ResultSet.new(nodes: Set.new(intersected_image.map{|img_node| img_node.parent}))
  
    end
    
    #TODO review this method
    def group_by_image()
      groups = {}

      grouped_nodes = children
      grouped_nodes.each do |node|
        node.children.each do |child|
          if !groups.has_key? child.item
            groups[child.item] = Xplain::Node.new(item: child.item)
          end
          groups[child.item] << Xplain::Node.new(item: node.item)
        end
      end
      ResultSet.new(nodes: groups.values)
    end
    
    #TODO it reverses only two first levels and ignore the remaining levels
    def reverse()
      new_parents = {}
      my_copy = self.copy
      my_copy.children.each do |child| 
        child.children_edges.each do |edge|
          if !new_parents[edge.target]
            new_parents[edge.target] = []
          end 
          new_parents[edge.target] << edge.origin
          
        end 
      end
      
      new_parents.each do |parent_node, children_nodes|
        parent_node.children_edges = []
        parent_node.parent_edges = []
        children_nodes.each{|child| child.parent_edges = []; child.children_edges = []}
        parent_node.children = children_nodes
      end
      my_copy.children = new_parents.keys
      my_copy
    end
  end
end