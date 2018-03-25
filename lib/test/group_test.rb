require './exceptions/invalid_input_exception'
require './test/xplain_unit_test'
require './operations/group'
require './operations/grouping_relations/grouping_relation'
require './operations/grouping_relations/by_image'


class GroupTest < XplainUnitTest

  def test_group_by_empty_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2")]
    input = Node.new('root')
    input.children = input_nodes
    
    begin
      rs = Group.new(input: input, grouping_relation: Grouping::ByImage.new(nil)).execute
      assert false, rs.inspect
    rescue MissingRelationException => e
      assert true, e.to_s
      return
    end
    assert false
  end
  
  def test_group_by_nil_input_set
    begin
      rs = Group.new(input: nil).execute
      assert false
    rescue InvalidInputException => e
      assert true, e.to_s
      return      
    end
    assert false, "Exception has not been raised!"
  end
  
  def test_group_by_empty_input_set
    root = Node.new("root")

    rs = Group.new(input: root).execute
    
    assert_true rs.children.empty?, rs.inspect
  end
  
  def test_group_by_single_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"),Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6") ]
    input = Node.new('root')
    input.children = input_nodes
    
    author_relation = Xplain::SchemaRelation.new(id: "_:author", inverse: true)
    rs = Group.new(input: input, grouping_relation: Grouping::ByImage.new(Xplain::SchemaRelation.new(id: "_:author"))).execute
    # binding.pry
    assert_equal Set.new([Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]), Set.new(rs.children.map{|node| node.item})
 
    a1 = rs.children.select{|g| g.item.id == "_:a1"}.first
    a2 = rs.children.select{|g| g.item.id == "_:a2"}.first
    
    assert_equal [author_relation], a1.children.map{|c| c.item}
    assert_equal [author_relation], a2.children.map{|c| c.item}
    
    author_relation_a1 = a1.children.first
    author_relation_a2 = a2.children.first

    a1_children = author_relation_a1.children.map{|c| c.item}.sort{|i1,i2| i1.to_s <=> i2.to_s}
    a2_children = author_relation_a2.children.map{|c| c.item}.sort{|i1,i2| i1.to_s <=> i2.to_s}
    
    assert_equal [Xplain::Entity.new("_:p2"),Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:paper1")], a1_children
    assert_equal [Xplain::Entity.new("_:p3"),Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")], a2_children
  end
  
  def test_group_by_inverse_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:k1"), Xplain::Entity.new("_:k2"), Xplain::Entity.new("_:k3")]
    input = Node.new('root')
    input.children = input_nodes
    
    keywords_relation = Xplain::SchemaRelation.new(id: "_:keywords")
    rs = Group.new(input: input, grouping_relation: Grouping::ByImage.new(Xplain::SchemaRelation.new(id: "_:keywords", inverse: true))).execute
    # binding.pry
    assert_equal Set.new([Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p5")]), Set.new(rs.children.map{|node| node.item})

    p1 = rs.children.select{|g| g.item.id == "_:paper1"}.first
    p2 = rs.children.select{|g| g.item.id == "_:p2"}.first
    p3 = rs.children.select{|g| g.item.id == "_:p3"}.first
    p5 = rs.children.select{|g| g.item.id == "_:p5"}.first
    # binding.pry
    assert_equal [keywords_relation], p1.children.map{|c| c.item}
    assert_equal [keywords_relation], p2.children.map{|c| c.item}
    assert_equal [keywords_relation], p3.children.map{|c| c.item}
    assert_equal [keywords_relation], p5.children.map{|c| c.item}
    
    assert_equal Set.new([Xplain::Entity.new("_:k1"), Xplain::Entity.new("_:k2"), Xplain::Entity.new("_:k3")]), Set.new(p1.children.first.children.map{|c|c.item})
    assert_equal Set.new([Xplain::Entity.new("_:k3")]), Set.new(p2.children.first.children.map{|c|c.item})
    assert_equal Set.new([Xplain::Entity.new("_:k2")]), Set.new(p3.children.first.children.map{|c|c.item})
    assert_equal Set.new([Xplain::Entity.new("_:k1")]), Set.new(p5.children.first.children.map{|c|c.item})
  end
  
  def test_group_by_path_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:publishedOn"), Xplain::SchemaRelation.new(id: "_:releaseYear")])
    inverse_path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:publishedOn", inverse: true), Xplain::SchemaRelation.new(id: "_:releaseYear", inverse: true)])
    input = Node.new('root')
    input.children = input_nodes

    rs = Group.new(input: input, grouping_relation: Grouping::ByImage.new(path)).execute

    assert_equal Set.new([Xplain::Literal.new(2005), Xplain::Literal.new(2010)]), Set.new(rs.children.map{|node| node.item})

    l2005 = rs.children.select{|g| g.item.value == 2005}.first
    l2010 = rs.children.select{|g| g.item.value == 2010}.first
    
    assert_equal [inverse_path], l2005.children.map{|c| c.item}
    assert_equal [inverse_path], l2010.children.map{|c| c.item}
    
    assert_equal Set.new([Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p4")]), Set.new(l2005.children.first.children.map{|c|c.item})
    assert_equal Set.new([Xplain::Entity.new("_:p3")]), Set.new(l2010.children.first.children.map{|c|c.item})
  end
  
  def test_group_by_inverse_path_relation
    input_nodes = create_nodes [Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:author", inverse: true), Xplain::SchemaRelation.new(id: "_:cite", inverse: true)])
    inverse_path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:author"), Xplain::SchemaRelation.new(id: "_:cite")])
    input = Node.new('root')
    input.children = input_nodes

    rs = Group.new(input: input, grouping_relation: Grouping::ByImage.new(path)).execute

    expected_groups = Set.new([Xplain::Entity.new("_:p7"),Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"), Xplain::Entity.new("_:p10"), Xplain::Entity.new("_:p6"), Xplain::Entity.new("_:paper1")])
    assert_equal expected_groups, Set.new(rs.children.map{|node| node.item})
    
    p7 = rs.children.select{|g| g.item.id == "_:p7"}.first
    p8 = rs.children.select{|g| g.item.id == "_:p8"}.first
    p9 = rs.children.select{|g| g.item.id == "_:p9"}.first
    p10 = rs.children.select{|g| g.item.id == "_:p10"}.first
    p6 = rs.children.select{|g| g.item.id == "_:p6"}.first
    paper1 = rs.children.select{|g| g.item.id == "_:paper1"}.first
    
    
    assert_equal [inverse_path], p7.children.map{|c| c.item}
    assert_equal [inverse_path], p8.children.map{|c| c.item}
    assert_equal [inverse_path], p9.children.map{|c| c.item}
    assert_equal [inverse_path], p10.children.map{|c| c.item}
    assert_equal [inverse_path], p6.children.map{|c| c.item}
    assert_equal [inverse_path], paper1.children.map{|c| c.item}
     

    assert_equal p6.children.first.children.size, 2
    assert_equal Set.new(p6.children.first.children.map{|node| node.item.id}), Set.new(["_:a1", "_:a2"])
    
  end
  
  def test_group_by_mixed_path
    input_nodes = create_nodes [Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p3"), Xplain::Entity.new("_:p4")]
    path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:cite", inverse: true), Xplain::SchemaRelation.new(id: "_:author")])
    inverse_path = Xplain::PathRelation.new(relations: [Xplain::SchemaRelation.new(id: "_:cite"), Xplain::SchemaRelation.new(id: "_:author", inverse: true)])
    input = Node.new('root')
    input.children = input_nodes

    rs = Group.new(input: input, grouping_relation: Grouping::ByImage.new(path)).execute
    
    assert_equal Set.new([Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]), Set.new(rs.children.map{|node| node.item})
    a1 = rs.children.select{|g| g.item.id == "_:a1"}.first
    a2 = rs.children.select{|g| g.item.id == "_:a2"}.first
    
    assert_equal [inverse_path], a1.children.map{|c| c.item}
    assert_equal [inverse_path], a2.children.map{|c| c.item}
    
    assert_equal Set.new(a1.children.first.children.map{|node| node.item.id}), Set.new(["_:p3", "_:p4"])
    assert_equal Set.new(a2.children.first.children.map{|node| node.item.id}), Set.new(["_:p5", "_:p3", "_:p4"])
  end
  
  def test_group_two_levels
    
    input_nodes = create_nodes [
      Xplain::Entity.new("_:paper1"), Xplain::Entity.new("_:p2"), Xplain::Entity.new("_:p3"),
      Xplain::Entity.new("_:p4"), Xplain::Entity.new("_:p5"), Xplain::Entity.new("_:p6"),
      Xplain::Entity.new("_:p7"), Xplain::Entity.new("_:p8"), Xplain::Entity.new("_:p9"),
    ]
    input = Node.new('root')
    input.children = input_nodes

    rs = Group.new(
      input: Group.new(input: input, grouping_relation: Grouping::ByImage.new(Xplain::SchemaRelation.new(id: "_:author"))).execute, 
      grouping_relation: Grouping::ByImage.new(Xplain::SchemaRelation.new(id: "_:publicationYear"))
    ).execute
    
    inverse_author = Xplain::SchemaRelation.new(id: "_:author", inverse: true)
    inverse_publicationYear = Xplain::SchemaRelation.new(id: "_:publicationYear", inverse: true)
    assert_equal Set.new([Xplain::Entity.new("_:a1"), Xplain::Entity.new("_:a2")]), Set.new(rs.children.map{|node| node.item})
    a1 = rs.children.select{|g| g.item.id == "_:a1"}.first
    a2 = rs.children.select{|g| g.item.id == "_:a2"}.first
    
    assert_equal [inverse_author], a1.children.map{|c| c.item}
    assert_equal [inverse_author], a2.children.map{|c| c.item}
    # binding.pry
    assert_equal Set.new(a1.children.first.children.map{|c| c.item}), Set.new([Xplain::Literal.new(1998),Xplain::Literal.new(2000)])
    assert_equal Set.new(a2.children.first.children.map{|c| c.item}), Set.new([Xplain::Literal.new(1998),Xplain::Literal.new(2000)])
    subg1 = a1.children.first.children.select{|g| g.item.value.to_s == '2000'}.first
    subg2 = a2.children.first.children.select{|g| g.item.value.to_s == '1998'}.first

    assert_equal [inverse_publicationYear], subg1.children.map{|c| c.item}
    assert_equal [inverse_publicationYear], subg2.children.map{|c| c.item}
    # binding.pry
    assert_equal Set.new(subg1.children.first.children.map{|n| n.item}), Set.new([Xplain::Entity.new("_:p2")])
    assert_equal Set.new(subg2.children.first.children.map{|n| n.item}), Set.new([Xplain::Entity.new("_:p3")])
    
  end

end