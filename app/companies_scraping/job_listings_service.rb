# frozen_string_literal: true

require_relative 'application'
# Class for Scraping job details
# STEP 1: call jobspikr API to get job details
# STEP 2: return job_details and summary
#   jobspikr_api_failed: false
#   job_details_found_from_api: false
#   company_jobs_matched: false

class JobListingsService
  include CommonHelper
  NUMBER_OF_DAYS = 30

  def initialize(company_details: {}, scraped_company_url: nil)
    @log = LoggerService.new
    @company_details = company_details
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @summary_hash = { jobspikr_api_failed: false, job_details_found_from_api: false, company_jobs_matched:false}
    @job_details_from_api = []
    @company_jobs_matched = []
    now = Date.today
    @to_date = now.strftime("%Y-%m-%d")
    @from_date = (now - NUMBER_OF_DAYS).strftime("%Y-%m-%d")
  end

  def job_listings
    @log.error('------ Begin JobListingsService ------')
    @job_details_from_api = get_jobspikr_response
    @company_jobs_matched = filter_company_jobs
    update_jobs_summary
    @log.error("------ Ends JobListingsService ------\n\n")
    { job_listings: @company_jobs_matched, summary: @summary_hash }
  end

  def get_jobspikr_response
    @log.error('-- started JobListingsService:get_jobspikr_response --')
    params = {
      company_details: @company_details,
      search_query: search_query,
      trigger: 'get_jobspikr_response'
    }
    @log.error('-- Ends JobListingsService:get_jobspikr_response --')
    JobspikrApiService.new(params).job_data
  end

  def filter_company_jobs
    return [] if @job_details_from_api.nil? || @job_details_from_api.empty?
    company_jobs_matched =[]
    @job_details_from_api.each do |job|
      company_jobs_matched.push(job) if alpha_numeric_string(job["company_name"]) ==  alpha_numeric_string(@company_name)
    end
    company_jobs_matched
  end

  def search_query
    {
      "format": "json",
      "size": 50,
      "dataset": [
        "job_board",
        "f500"
      ],
      "search_query_json": {
        "bool": {
          "must": [
            {
              "query_string": {
                "fields": [
                  "job_title",
                  "inferred_job_title"
                ],
                "query": "*"
              }
            },
            {
              "query_string": {
                "default_field": "job_type",
                "query": "*"
              }
            },
            {
              "query_string": {
                "default_field": "company_name",
                "query": "#{@company_name}"
              }
            },
            {
              "range": {
                "post_date": {
                  "gte": "#{@from_date}",
                  "lte": "#{@to_date}"
                }
              }
            }
          ],
          "must_not": [
            {
              "query_string": {
                "default_field": "company_name",
                "query": "Unspecified"
              }
            }
          ]
        }
      }
    }
  
  end

  def update_jobs_summary
    if @job_details_from_api && @job_details_from_api&.length&.positive?
      @summary_hash[:job_details_found_from_api] = true
      @summary_hash[:company_jobs_matched] = true if @company_jobs_matched&.length&.positive?
    else
      csv_inputs = {
        company_name: @company_name,
        err_type: 'job_data_not_found',
        trigger: 'job_listings',
        err_message: 'Jobs data not found',
        err_service: 'JOB_LISTINGS_SERVICE'
      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('Not_found job_data: JobListingsService : Jobs Data not found')
      @summary_hash[:jobspikr_api_failed] = true
    end
  end
end
