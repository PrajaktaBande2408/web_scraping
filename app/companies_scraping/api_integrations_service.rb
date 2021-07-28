# frozen_string_literal: true

require_relative 'application'
require '../../utils/company_scraping/api_integrations_service_helper'

# Class for context backend API integrations
class ApiIntegrationsService
  include ApiIntegrationsServiceHelper

  def initialize(opts: {})
    @log = LoggerService.new
    @payload = opts[:payload]
    @method = opts[:method]
    @url = set_url(opts[:url])
    @headers = set_headers
    @company_name = opts[:company_name]
    @trigger = opts[:trigger]
  end

  def call
    execute && set_response
  end

  def execute
    begin
      @response = RestClient::Request.execute(
        method: @method,
        url: @url,
        payload: @payload.to_json,
        headers: @headers
      )
      success = true
    rescue StandardError => e
      success = failure_response('execute', e.message)
    end
    success
  end

  def set_response
    return { success: false, resp_body: [] } unless @response&.body || @response.code != 200

    begin
      resp_body = JSON.parse(@response.body)
      success = resp_body['status_code'] == 1000
    rescue StandardError => e
      success = failure_response('set_response', e.message)
    end
    { success: success, resp_body: resp_body }
  end
end
