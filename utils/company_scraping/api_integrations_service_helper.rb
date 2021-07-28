# frozen_string_literal: true

# module for common methods for API integration service
module ApiIntegrationsServiceHelper
  def set_headers
    {
      'Authorization' => ENV.fetch('CB_AUTH_TOKEN'),
      'Content-Type' => 'json'
    }
  end

  def set_url(url)
    ENV.fetch('CB_API_HOST') + url
  end

  def failure_response(method_name, exception_message)
    # Adding Exceptions to logs CSV
    csv_inputs = {
      company_name: @company_name,
      trigger: @trigger,
      err_message: exception_message,
      err_type: method_name,
      err_service: 'API_INTEGRATION_SERVICE'

    }
    @log.csv_logs(opts: csv_inputs)

    @log.error("Exception for #{method_name}: #{@trigger} : #{exception_message}")
    false
  end
end
