# frozen_string_literal: true

require_relative 'application'
# Class for calculating and displaying summary

# valid_url_given: false,
# fetch_from_clearbit:
# {
#    empty_response_from_clearbit: true/false
#    url_match_algo:"name/domain"
#    url_match_algo_failed: true/false
#    clearbit_api_exception: true
#  }
# fetch_from_googlesearch: true/false
# homepage_content_found: true/false
# about_us_url_found: true/false
# about_us_content_found: true/false
# press_urls_found: true/false
# press_summary_found: true/false
# press_releases_found: false
# news_gsearch_results_found: true/false
# news_content_found: true/false
# news_destination_content_found: true/false
# jobspikr_api_failed: false
# job_details_found_from_api_from_api: false
# company_jobs_matched: false

# company_upsert_success: true/false
# company_scrape_upsert_success: true/false
# db_updation_success: true/false

class SummaryService
  def initialize(summary_json: {})
    @log = LoggerService.new
    @summary_json = summary_json

    set_counters
    update_counters
    print_summary
  end

  def set_counters
    @valid_urls_given_for  = 0
    @fetched_from_clearbit = 0
    @empty_response_from_clearbit = 0
    @url_name_matched_algo = 0
    @url_domain_matched_algo = 0
    @url_match_algo_failed = 0
    @clearbit_api_exception = 0
    @fetched_from_googlesearch = 0

    @homepage_content_found = 0

    @about_us_url_found = 0
    @about_us_content_found = 0

    @press_urls_found = 0
    @press_summary_found = 0
    @press_releases_found = 0

    @news_gsearch_results_found = 0
    @news_content_found = 0
    @news_destination_content_found = 0

    @jobspikr_api_failed = 0
    @job_details_found_from_api = 0
    @company_jobs_matched = 0

    @company_upsert_success = 0
    @company_scrape_upsert_success = 0
    @db_updation_success = 0
  end

  def update_counters
    @summary_json.each do |company_name, json|
      next if company_name.to_s == 'total_companies'

      # company service
      update_company_url_counter(json)
      # homepage
      @homepage_content_found += 1 if json[:homepage_content_found]
      # about us
      @about_us_url_found += 1 if json[:about_us_url_found]
      @about_us_content_found += 1 if json[:about_us_content_found]
      # press
      @press_urls_found += 1 if json[:press_urls_found]
      @press_summary_found += 1 if json[:press_summary_found]
      @press_releases_found += 1 if json[:press_releases_found]
      # news
      @news_gsearch_results_found += 1 if json[:news_gsearch_results_found]
      @news_content_found += 1 if json[:news_content_found]
      @news_destination_content_found += 1 if json[:news_destination_content_found]

      #jobs
      @jobspikr_api_failed += 1 if json[:jobspikr_api_failed]
      @job_details_found_from_api += 1 if json[:job_details_found_from_api]
      @company_jobs_matched +=1 if json[:company_jobs_matched]

      # db connection
      @company_upsert_success += 1 if json[:company_upsert_success]
      @company_scrape_upsert_success += 1 if json[:company_scrape_upsert_success]
      @db_updation_success += 1 if json[:db_updation_success]
      
    end
  end

  def update_company_url_counter(json)
    @valid_urls_given_for += 1 if json[:valid_url_given]
    @fetched_from_googlesearch += 1 if json[:fetch_from_googlesearch]

    if json[:fetch_from_clearbit]
      @empty_response_from_clearbit += 1 if json[:fetch_from_clearbit][:empty_response_from_clearbit]
      @url_match_algo_failed += 1 if json[:fetch_from_clearbit][:url_match_algo_failed]
      @clearbit_api_exception += 1 if json[:fetch_from_clearbit][:clearbit_api_exception]

      unless json[:fetch_from_clearbit][:url_match_algo].empty?
        @fetched_from_clearbit += 1
        case json[:fetch_from_clearbit][:url_match_algo]
        when 'name'
          @url_name_matched_algo += 1
        when 'domain'
          @url_domain_matched_algo += 1
        end
      end
    end
  end

  def print_summary
    @log.error('======= Begin SummaryService =======')
    @log.error("Total companies  : #{total_companies}")
    @log.error("Existing Valid company Urls  : #{@valid_urls_given_for}")
    @log.error("Not Existing valid company Urls  : #{total_companies - @valid_urls_given_for}")

    @log.error("Company URL fetched from clearbit(success) : #{@fetched_from_clearbit}")
    @log.error("Clearbit Name Algo success : #{@url_name_matched_algo}")
    @log.error("Clearbit Domain Algo success : #{@url_domain_matched_algo}")
    @log.error("Clearbit API exception : #{@clearbit_api_exception}")
    @log.error("Empty Response from clearbit: #{@empty_response_from_clearbit}")
    @log.error("Clearbit name/domain algo Failed : #{@url_match_algo_failed}")
    @log.error("Company URL fetched from clearbit(failed) : #{@clearbit_api_exception + @empty_response_from_clearbit + @url_match_algo_failed}")
    @log.error("Company URL fetched from Googlesearch : #{@fetched_from_googlesearch}")
   
    @log.error("Homepage Content Found: #{@homepage_content_found}")
    @log.error("Homepage Content Not Found: #{total_companies - @homepage_content_found}")

    @log.error("About Us URLs Found : #{@about_us_url_found}")
    @log.error("About Us URLs NOT Found : #{total_companies - @about_us_url_found}")
    @log.error("About Us Content Found : #{@about_us_content_found}")
    @log.error("About Us Content NOT Found : #{total_companies - @about_us_content_found}")

    @log.error("Press URLs Found : #{@press_urls_found}")
    @log.error("Press URLs NOT Found : #{total_companies - @press_urls_found}")

    @log.error("Press summary Found : #{@press_summary_found}")
    @log.error("Press summary NOT Found : #{total_companies - @press_summary_found}")
    @log.error("Press releases Found : #{@press_releases_found}")
    @log.error("Press releases NOT Found : #{total_companies - @press_releases_found}")

    @log.error("News google search results found : #{@news_gsearch_results_found}")
    @log.error("News google search results NOT found : #{total_companies - @news_gsearch_results_found}")
    
    @log.error("News content found : #{@news_content_found}")
    @log.error("News content NOT found : #{total_companies - @news_content_found}")
    @log.error("News destination content found: #{@news_destination_content_found}")
    @log.error("News destination content not found: #{total_companies - @news_destination_content_found}")
    
    @log.error("Job Details found from API: #{@job_details_found_from_api}")
    @log.error("Job Details matched with company name: #{@company_jobs_matched}")
    @log.error("Jobspikr API Failed for : #{@jobspikr_api_failed}")
    
    @log.error("company_upsert_success : #{@company_upsert_success}")
    @log.error("company_scrape_upsert_success : #{@company_scrape_upsert_success}")
    @log.error("db_updation_success : #{@db_updation_success}")
    @log.error("db_updation_failed : #{total_companies - @db_updation_success}")

    @log.error('======= Ends SummaryService =======')
  end

  def total_companies
    @summary_json[:total_companies]
  end

  def perc(i, j)
    i * 100 / j
  rescue StandardError
    0
  end
end
