# frozen_string_literal: true

# module for company_url fetching methods
module CompanyUrlServiceHelper
  # validating already Existing URLs
  def valid_existing_url(url)
    return '' if url.nil? || url.empty?

    url = url.gsub('https://www.', '').gsub('http://www.', '').gsub('https://', '').gsub('http://', '').gsub('www.', '')
    url = "https://www.#{url}"
    begin
      uri = URI.parse(url)
    rescue StandardError
      url = ''
    end
    url
  end

  def execute_clearbit_api
    success = true
    begin
      clearbit_url = "https://autocomplete.clearbit.com/v1/companies/suggest?query=#{get_formated_company_name(@company_name)}"
      @response = RestClient::Request.execute(
        method: 'GET',
        url: clearbit_url,
        content_type: :json
      )
    rescue StandardError => e
      success = failure_response('execute_clearbit_api', e.message)
    end
    success
  end

  def set_response
    return { success: false, resp_body: [] } unless @response&.body || @response.code != 200

    begin
      resp_body = JSON.parse(@response.body)
      success = true
    rescue StandardError => e
      success = failure_response('set_response', e.message)
    end
    { success: success, resp_body: resp_body }
  end

  def failure_response(method_name, exception_message)
    # Adding Exceptions to logs CSV
    csv_inputs = {
      company_name: @company_name,
      trigger: 'company_url_service',
      err_message: exception_message,
      err_type: method_name,
      err_service: 'COMPANY_URL_SERVICE'
    }
    @log.csv_logs(opts: csv_inputs)
    @summary_hash[:fetch_from_clearbit][:clearbit_api_exception] = true
    @log.error("Exception for fetch_url_from_clearbit: #{method_name} : #{exception_message}")
    false
  end

  def process_company_url_algo(resp)
    if resp[:resp_body].empty?
      @summary_hash[:fetch_from_clearbit][:empty_response_from_clearbit] = true
      failure_response('process_company_url_algo', '[] response from clearbit API')
      ''
    else
      # body is [] of multiple related companies with name and domain
      # If URL matching with name failed then URL matching with domain
      url = url_match_by_name(resp[:resp_body], @company_name)
      url = url_match_by_domain(resp[:resp_body], @company_name) if url.empty?

      # Name && domain match algorith failed
      if url.empty?
        @summary_hash[:fetch_from_clearbit][:url_match_algo_failed] = true
        failure_response('process_company_url_algo', 'URL match Algorithm Failed')
      end
      url
    end
  end

  # Finds URL by matching company_name and body["name"]
  def url_match_by_name(body, company_name)
    url = ''
    formated_c_name = get_formated_company_name(company_name)

    body.each do |b|
      next unless b['name'].downcase.gsub(/[^0-9A-Za-z]/, '') == formated_c_name

      url = "https://www.#{b['domain']}"
      @summary_hash[:fetch_from_clearbit][:url_match_algo] = 'name'
      break
    end
    url
  end

  # Finds URL by matching company_name and body["domain"]
  def url_match_by_domain(body, company_name)
    url = ''
    # As Domains are always downcase with no special characters
    formated_c_name = get_formated_company_name(company_name)

    body.each do |b|
      next unless (b['domain'].split('.')[0]).match(formated_c_name)

      url = "https://www.#{b['domain']}"
      @summary_hash[:fetch_from_clearbit][:url_match_algo] = 'domain'
      break
    end
    url
  end

  # returns company_name alphanumeric with downcase and ignoring special keywords eg.inc/llp
  def get_formated_company_name(company_name)
    company_name.downcase.gsub(/[^0-9A-Za-z]/, '').gsub('inc', '').gsub('llp', '')
  end

  def get_google_search_results
    @log.error('-- started company_url_service:get_google_search_results --')
    params = {
      company_details: @company_details,
      search_query: search_query,
      trigger: 'company_url_service'
    }
    @log.error('-- Ends company_url_service:get_google_search_results --')
    GoogleSearchApiService.new(params).search_results
  end

  def search_query
    "intitle:\"#{@company_name}\" homepage"
  end

  def exctract_company_url(url)
    begin
      uri = URI.parse(url)
      company_name = get_formated_company_name(@company_name)
      url = "#{uri.scheme}://#{uri.host}" if contains_keyword(company_name, [uri.host.downcase.split('.')[1]])
    rescue StandardError => e
      url = url
      @log.error("exctract_company_url: Parse url: #{e.message}")
    end
    url
  end
end
