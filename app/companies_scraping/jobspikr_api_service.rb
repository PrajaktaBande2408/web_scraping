# frozen_string_literal: true

# Class forGoogle search API
class JobspikrApiService
  def initialize(company_details: {}, search_query: '', trigger: '')
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @search_query = search_query
    @headers = set_headers
    @trigger = trigger
    @resp_body = nil
    @success = false
    @job_data = []
    # Executing API
    call
  end

  def call
    execute && set_response && set_job_data
  end

  def execute
    begin
      retries ||= 0
      @log.error("try ##{ retries }")
      @response = RestClient::Request.execute(
        method: 'POST',
        url: 'https://api.jobspikr.com/v2/data',
        payload: @search_query.to_json,
        headers: @headers
      )
      @success = true
    rescue StandardError => e
      @success = failure_response('JobsPikr_API_execute', e.message)
      retry if (retries += 1) < 3
    end
    @success
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

  def set_job_data
    @job_data = @resp_body['job_data'] if @success
  end

  def set_headers
    {
      'Content-Type' => 'json',
      'client_id' => ENV.fetch('JOBSPIKR_CLIENT_ID'),
      'client_auth_key' => ENV.fetch('JOBSPIKR_CLIENT_AUTH_KEY')
    }
  end

  def failure_response(method_name, exception_message)
    # Adding Exceptions to logs CSV
    csv_inputs = {
      company_name: @company_name,
      trigger: @trigger,
      err_message: exception_message,
      err_type: method_name,
      err_service: 'JOBSPIKR_API_SERVICE'
    }
    @log.csv_logs(opts: csv_inputs)
    @log.error("Exception for #{method_name}: #{@trigger} : #{exception_message}")
    false
  end
  
  def job_data
    update_logs unless @job_data&.length&.positive?
    @job_data
  end

  def update_logs
    csv_inputs = {
      company_name: @company_name,
      trigger: @trigger,
      err_message: "Not_found jobspikr_search_results: #{@trigger}",
      err_type: 'jobspikr_search_results_not_found',
      err_service: 'JOBSPIKR_API_SERVICE'

    }
    @log.csv_logs(opts: csv_inputs)
    @log.error("Not_found jobspikr_search_results: #{@trigger}")
  end
end
