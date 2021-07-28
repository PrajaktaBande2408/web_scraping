# frozen_string_literal: true

require_relative 'application'
require '../../utils/company_scraping/company_url_service_helper'
# Class for fetching company_url
# STEP 1: URL = validate URL
# STEP 2: fetch_company_url from clearbit if URL invalid
# STEP 3: return valid url
# STEP 4: return company_url and summary
#   valid_url_given: false,
#   fetch_from_clearbit: {
#      empty_response_from_clearbit: true/false
#      url_match_algo:"name/domain"
#      url_match_algo_failed: true/false
#      clearbit_api_exception: true }
#   fetch_from_googlesearch: true/fasle

class CompanyUrlService
  include CompanyUrlServiceHelper
  include CommonHelper

  def initialize(company_details: {})
    @log = LoggerService.new
    @company_details = company_details
    @company_name = company_details[:company_name]
    # TO DO: csvs contains multiple urls for one company
    @tmp_company_url = company_details[:company_url]&.split(',')[0]
    @company_url = ''
    @summary_hash = {
      valid_url_given: false,
      fetch_from_clearbit: {
        empty_response_from_clearbit: false,
        url_match_algo: '',
        url_match_algo_failed: false,
        clearbit_api_exception: false
      },
      fetch_from_googlesearch: false
    }
  end

  def url
    @log.error('------ Begin CompanyUrlService ------')
    @company_url = valid_existing_url(@tmp_company_url)

    if @company_url.empty?
      @company_url = fetch_url_from_clearbit(@company_name)
      @company_url = fetch_from_google_search(@company_name) if @company_url.empty?
    else
      @summary_hash[:valid_url_given] = true
    end
    @log.error("------ Ends CompanyUrlService ------\n\n")
    { company_url: @company_url, summary: @summary_hash }
  end

  def fetch_url_from_clearbit(company_name)
    @log.error("Fetching company url with clearbit for: #{company_name} ")

    resp_body = execute_clearbit_api && set_response

    return '' unless resp_body && resp_body[:success]

    # Processing url algo to find url from name or domain match
    process_company_url_algo(resp_body)
  end

  def fetch_from_google_search(company_name)
    @log.error("Fetching company url with google search for: #{company_name} ")
    search_results = get_google_search_results
    if search_results.length.positive?
      url = exctract_company_url(search_results[0]['url'])
      @summary_hash[:fetch_from_googlesearch] = true unless url.empty?
    end
    url
  end
end
