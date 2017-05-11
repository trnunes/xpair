Dir["/Users/tnunes/development/xpair/mixins/*.rb"].each {|file| require file }
Dir["/Users/tnunes/development/xpair/model/*.rb"].each {|file| require file }
Dir["/Users/tnunes/development/xpair/aux/*.rb"].each {|file| require file }
Dir["/Users/tnunes/development/xpair/adapters/rdf/*.rb"].each {|file| require file }

require 'mixins/xpair'
require 'mixins/auxiliary_operations'
require 'mixins/explorable'
require 'mixins/enumerable'
require 'mixins/persistable'
require 'mixins/graph'

require 'exploration_functions/operation'
require 'exploration_functions/find_relations'
require 'exploration_functions/pivot2'
require 'exploration_functions/refine'
require 'exploration_functions/group'
require 'exploration_functions/map'
require 'exploration_functions/flatten'
require 'exploration_functions/union'
require 'exploration_functions/intersection'
require 'exploration_functions/diff'
require 'exploration_functions/rank'
require 'exploration_functions/select'

require 'filters/filtering'
require 'filters/contains'
require 'filters/equals'
require 'filters/keyword_match'
require 'filters/match'
require 'filters/in_range'
require 'filters/image_equals'
require 'filters/compare'

require 'grouping_functions/grouping'
require 'grouping_functions/by_relation'
require 'grouping_functions/by_domain'

require 'ranking_functions/ranking'
require 'ranking_functions/alpha_sort'
require 'ranking_functions/by_relation'

require 'mapping_functions/mapping'
require 'mapping_functions/average'
require 'mapping_functions/count'
require 'mapping_functions/image_count'
require 'mapping_functions/user_defined'

require 'model/item'
require 'model/xset'
require 'model/entity'
require 'model/literal'
require 'model/relation'
require 'model/type'
require 'model/ranked_set'
require 'model/xsubset'
require 'model/namespace'
require 'model/session'

require 'aux/grouping_expression.rb'
require 'aux/ranking_functions'
require 'aux/mapping_functions'
require 'aux/hash_helper'

require 'set'

require 'adapters/rdf/rdf_data_server.rb'
require 'adapters/rdf/rdf_filter2.rb'
require 'adapters/rdf/rdf_nav_query2.rb'
require 'adapters/rdf/cache.rb'

$PAGINATE = 10
##TODO BUGS TO CORRECT
## contains_one does not admit literals
## TODO implement the generation of a view expression and the generation of a ruby expression in the DSL
## TODO implement a session id for each set
## TODO implement a session object
##TODO IMPLEMENT THE PROJECTION
## TODO relationship query between pairs
##