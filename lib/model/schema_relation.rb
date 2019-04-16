module Xplain
  class SchemaRelation < Item
    include Xplain::GraphConverter
    include Xplain::Relation
    attr_accessor :inverse
    @@meta_relations = [:relations, :has_type, :relations_domain, :relations_image]
    
    def initialize(params={})
      super(params)
      @inverse = params[:inverse] || false
    end
    
    def meta?
      @@meta_relations.include? @id.to_sym      
    end
    
    def text
      text_to_return = @text.to_s
      text_to_return = @id.dup.to_s if text_to_return.empty?
      text_to_return << " of" if inverse?
      text_to_return      
    end
    
    def inverse?
      @inverse
    end
    
    def delegate_meta_relation(method_suffix, restriction=nil, options={})
      inverse_method_suffix = 
        if method_suffix.include? "image"
          method_suffix.gsub("image", "domain")
        else
          method_suffix.gsub("domain", "image")
        end
      result_set =  
        if self.inverse?
          if restriction
            
            @server.send((@id + inverse_method_suffix).to_sym, restriction, options)
          else
            @server.send((@id + inverse_method_suffix).to_sym, options)
          end
        else
          if restriction
            @server.send((@id + method_suffix).to_sym, restriction, options)
          else
            @server.send((@id + method_suffix).to_sym, options)
          end
        end
      return result_set          
    end
    
    def reverse
      Xplain::SchemaRelation.new(id: id, inverse: !inverse?)
    end
    
    def image(offset=0, limit=nil)
      if self.meta?
        return delegate_meta_relation("_image", nil, {offset: offset, limit: limit})
      end

      @server.image(self, offset.to_i, limit.to_i)
    end
  
    def domain(offset=0, limit=-1)
      if self.meta?
        return delegate_meta_relation("_domain", nil, {offset: offset, limit: limit})
      end

      @server.domain(self, offset, limit)
    end
  
    def restricted_image(restriction, options= {})
      if self.meta?
        return delegate_meta_relation("_restricted_image", restriction, options)
      end

      @server.restricted_image(self, restriction, options)
    end
  
    def restricted_domain(restriction, options = {})
      if self.meta?
        return delegate_meta_relation("_restricted_domain", restriction, options)
      end

      @server.restricted_domain(self, restriction, options)
    end
  end
end