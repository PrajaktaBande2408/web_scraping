# frozen_string_literal: true

require_relative 'application'
# Class for All DB updation
# STEP 1: update company table
# STEP 2: update company_scrape table
# STEP 5: return  resp and summary
#   company_upsert_success: true/false
#   company_scrape_upsert_success: true/false
#   db_updation_success: true/false


class DbConnectionService
  def initialize(company_details: {}, json_scrape: {})
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @json_scrape = json_scrape
    @summary_hash = {
      company_upsert_success: false,
      company_scrape_upsert_success: false,
      db_updation_success: false
    }
  end

  def update_company_and_company_scrape
    @log.error('------ Begin DbConnectionService ------')
    success = company_upsert && company_scrape_upsert
    @log.error('------ Ends DbConnectionService ------')
    @summary_hash[:db_updation_success] = success
    { success: success, summary: @summary_hash }
  end

  def company_upsert
    @log.error('-- Begin company_upsert --')

    opts = {
      payload: company_upsert_payload,
      method: 'POST',
      url: 'v1/company-upsert',
      company_name: @company_name,
      trigger: 'company_upsert'
    }

    resp = ApiIntegrationsService.new(opts: opts).call
    @summary_hash[:company_upsert_success] = resp[:success]
    @log.error('-- Ends company_upsert --')
    resp[:success]
  end

  def company_upsert_payload
    {
      'name' => @company_name,
      'client_code' => '',
      'json_definition' => {},
      'linkedin_url' => '',
      'dnb_number' => '',
      'experian_number' => '',
      'company_url' => @company_url || ''
    }
  end

  def company_scrape_upsert
    return false if @json_scrape.nil? || @json_scrape.empty?

    @log.error('-- Begin company_scrape_upsert --')
    opts = {
      payload: company_scrape_upsert_payload,
      method: 'POST',
      url: 'v1/company-scrape-insert',
      company_name: @company_name,
      trigger: 'company_scrape_upsert'
    }

    resp = ApiIntegrationsService.new(opts: opts).call
    @summary_hash[:company_scrape_upsert_success] = resp[:success]
    @log.error('-- Ends company_scrape_upsert --')
    resp[:success]
  end

  def company_scrape_upsert_payload
    {
      "name": @company_name,
      "client_code": '',
      "data_source_public": 'company_website',
      "data_source_client": '',
      "json_scrape": @json_scrape
    }
  end
end
