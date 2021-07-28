# frozen_string_literal: true

require 'json'
# Class for generating query
class FtsSearch
  def initialize(params)
    @params = params
    puts generate_dynamic_query
  end

  def generate_dynamic_query
    return { "Error": 'default_terms are mandatory for FTS query.' } if invalid_param('default_terms')

    query = 'SELECT '
    query += "#{response_fields} "
    query += 'FROM '
    query += table_name
    query += ' WHERE '
    query += fts_node_query
    query += data_source_clause
    query + limit_offset
  end

  # returns fields which we want in sql results
  def response_fields
    return '*' if invalid_param('response_fields')

    @params['response_fields'].join(', ')
  end

  # returns tablename on which we are going to query
  def table_name
    return 'contact_scrape' if invalid_param('table_name')

    @params['table_name']
  end

  # returns columnname on which we are going to query.
  def column_name
    return 'json_scrape' if invalid_param('column_name')

    @params['column_name']
  end

  # returns FTS condition on json node for searching particular terms based on inputs
  # Eg. to_tsvector('english',title_node) @@ to_tsquery('Contact & Center')

  # Example for inputs:
  # fts_conditions = [{"node_path": ['body', 'title'], "terms": "(contact & call)"}]
  # It will search terms from json > body > title node
  # (contact & call) : will return records if both contact and call present
  # (contact | call) : will return records if either contact or call present
  # (contact <-> call) : will return records if both contact and call are adjacent to each other
  # (contact <1> call) : will return records if call is present only after contact
  # (contact <3> call) : will return records if call is present after contact on third position

  # All conditions for terms with example are documented below:
  # https://docs.google.com/spreadsheets/d/1RCmbghaaZT6yJEBvFL6c40nOzeynRrAxZekp_sdbtgA/edit?usp=sharing
  def fts_node_query
    return fts_json_query if invalid_param('fts_conditions')

    fts_queries = []
    @params['fts_conditions'].each do |node|
      temp_query = "to_tsvector('english', jsonb_extract_path(#{column_name},'#{node['node_path'].join("', '")}'))"
      temp_query += " @@ to_tsquery('#{node['terms'] || default_terms}')"
      fts_queries.push(temp_query)
    end

    fts_queries.join(" #{query_condition_for_nodes} ")
  end

  # default FTS condition on whole json_scrape if fts conditions not passed in input.
  def fts_json_query
    "to_tsvector('english', json_scrape) @@ to_tsquery('#{default_terms}')"
  end

  # @params["default_terms"] is mandatory.
  def default_terms
    @params['default_terms']
  end

  def query_condition_for_nodes
    return 'OR' if invalid_param('query_condition_for_nodes')

    @params['query_condition_for_nodes']
  end

  # condition for data_source_client
  def data_source_clause
    return ' AND data_source_client IS NULL' if invalid_param('source_name')

    " AND data_source_client = '#{@params['source_name']}'"
  end

  def limit_offset
    " limit #{@params['limit'] || 10} offset #{@params['offset'] || 0}"
  end

  def invalid_param(param_name)
    @params[param_name].nil? || @params[param_name].empty?
  end
end

# Example Input
# Runtime settings (Trigger): search_query.lambda_handler
params = {
  'response_fields' => %w[id contact_id],
  'table_name' => 'contact_scrape',
  'column_name' => 'json_scrape',
  'fts_conditions' => [
    {
      'node_path' => %w[body headline],
      'terms' => '(contact & call)'
    },
    {
      'node_path' => %w[body summary],
      'terms' => '(digital & transformation)'
    },
    {
      'node_path' => %w[body experience],
      'terms' => '(digital <-> transformation)'
    }
  ],
  'default_terms' => '(digital & transformation)',
  'query_condition_for_nodes' => 'OR',
  'source_name' => '',
  'limit' => 10,
  'offset' => 0
}

FtsSearch.new(params)
