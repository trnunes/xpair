module Xplain::RDF
  module SessionMapper
    
    def session_add_result_set(session, result_set)
      insert_stmt = "INSERT DATA{
      <#{@xplain_ns.uri + session.id}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>.
      <#{@xplain_ns.uri + session.id}> <#{@dcterms.uri}title> \"#{session.title}\". 
      <#{@xplain_ns.uri + session.id}> <#{@xplain_ns.uri}contains_set> <#{@xplain_ns.uri + result_set.id}>}"
      execute_update(insert_stmt, content_type: content_type)
    end
    
    def session_remove_result_set(session, result_set)
      insert_stmt = "DELETE DATA{
      <#{@xplain_ns.uri + session.id}> <#{@xplain_ns.uri}contains_set> <#{@xplain_ns.uri + result_set.id}>}"
      execute_update(insert_stmt, content_type: content_type)
    end
    
    def session_save(session)
      insert_stmt = "INSERT DATA{
      <#{@xplain_ns.uri + session.id}> <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>.
      <#{@xplain_ns.uri + session.id}> <#{@dcterms.uri}title> \"#{session.title}\"}"
      execute_update(insert_stmt, content_type: content_type)
    end
    
    def session_load(id)
      session_query = "SELECT ?t WHERE{<#{@xplain_ns.uri + id}> <#{@dcterms.uri}title> ?t}"
      session = nil
      @graph.query(session_query).each do |solution|
        title = solution[:t].to_s
        session = Xplain::Session.new(id, title)
      end
      session      
    end
    
    def session_find_by_title(title)
      session_query = "SELECT ?s WHERE{?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>. ?s <#{@dcterms.uri}title> \"#{title}\"}"
      sessions = []
      @graph.query(session_query).each do |solution|
        session_id = solution[:s].to_s.gsub(@xplain_ns.uri, "")
        sessions << Xplain::Session.new(session_id, title)
      end
      sessions
    end
    
    def session_list_titles
      session_query = "SELECT ?t WHERE{?s <#{@rdf_ns.uri}type> <#{@xplain_ns.uri}Session>. ?s <#{@dcterms.uri}title> ?t}"
      titles = []
      @graph.query(session_query).each do |solution|
        titles << solution[:t].to_s
      end
      titles
    end
    
    def session_delete(session)
      delete_stmt = "DELETE WHERE{<#{@xplain_ns.uri + session.id}> ?p ?o}"
      execute_update(delete_stmt, content_type: content_type)
    end
  end
end