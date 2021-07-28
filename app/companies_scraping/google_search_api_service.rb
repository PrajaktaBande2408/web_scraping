# frozen_string_literal: true

# Class forGoogle search API
class GoogleSearchApiService
  def initialize(company_details: {}, search_query: '', trigger: '')
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @search_query = search_query
    @trigger = trigger
    @resp_body = nil
    @success = false
    @search_results = []
    # Executing API
    call
  end

  def call
    execute && set_response && set_search_results
  end

  def execute
    begin
      retries ||= 0
      @log.error("try ##{ retries }")
      @response = RestClient::Request.execute(
        method: 'GET',
        url: 'https://api.proxycrawl.com/',
        payload: payload
      )
      @success = true
    rescue StandardError => e
      @success = failure_response('google_search_API_execute', e.message)
      retry if (retries += 1) < 3
    end
    @success
  end

  def payload
    {
      token: ENV.fetch('PROXY_CRAWL_API_TOKEN'),
      url: "https://www.google.com/search?q=#{@search_query}",
      scraper: 'google-serp'
    }
  end

  def failure_response(method_name, exception_message)
    # Adding Exceptions to logs CSV
    csv_inputs = {
      company_name: @company_name,
      trigger: @trigger,
      err_message: exception_message,
      err_type: method_name,
      err_service: 'GOOGLE_SEARCH_API_SERVICE'
    }
    @log.csv_logs(opts: csv_inputs)
    @log.error("Exception for #{method_name}: #{@trigger} : #{exception_message}")
    false
  end

  def set_response
    @success = false unless @response&.body || @response.code != 200

    begin
      @resp_body = JSON.parse(@response.body)
      @success = true
    rescue StandardError => e
      @success = failure_response('set_response', e.message)
    end
    @success
  end

  def set_search_results
    @search_results = @resp_body['body']['searchResults'] if @success
  end

  def search_results
    update_logs unless @search_results.length.positive?
    @search_results
  end

  def update_logs
    csv_inputs = {
      company_name: @company_name,
      trigger: @trigger,
      err_message: "Not_found search_results: #{@trigger}",
      err_type: 'search_results_not_found',
      err_service: 'GOOGLE_SEARCH_API_SERVICE'

    }
    @log.csv_logs(opts: csv_inputs)
    @log.error("Not_found search_results: #{@trigger}")
  end
end
