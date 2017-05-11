class Item
  include Xpair::Graph
  attr_accessor :servers, :id, :text
  
  def initialize(id)
    @id = Xpair::Namespace.expand_uri(id.gsub(" ", "%20"))
    @servers = []
  end 
  
  def add_server(server)
    @servers << server
  end
    
  def relation?
    false
  end
  
  def type?
    false
  end
  
  def entity?
    false
  end
    
  def literal?
    false
  end
  
  def set?
    false
  end
  
  def text
    if @text.to_s.empty?
      @text = Xpair::Namespace.colapse_uri(id)
    end
    @text
  end
  
  def eql?(item)
    if !item.respond_to? :id
      return false
    end
    @id == item.id
  end
  
  def hash
    @id.hash
  end
  
  def to_s
    @id.to_s
  end
  alias == eql?
end