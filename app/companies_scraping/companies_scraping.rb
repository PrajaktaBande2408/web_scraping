# frozen_string_literal: true

require_relative 'application'

# Class for companies scraping process
class CompaniesScraping
  def initialize
    @log = LoggerService.new
    @log.clear_logs
    @summary_json = {}
    initilise_scraping
  end

  def initilise_scraping
    # STEP 1: Collect companies list
    company_list = CollectCompanyListService.new.collect_companies_list
    @summary_json.merge!({ total_companies: company_list.length })

    # STEP 2: Initialise individual company scraping
    company_list.each do |company_details|
      start_company_scrape_process(company_details)
    end

    # STEP 4: print summary
    SummaryService.new(summary_json: @summary_json)
  end

  def start_company_scrape_process(company_details)
    @log.error('********************** BEGIN COMPANY SCRAPE PROCESS **********************')

    company_details = {
      company_name: company_details['company_name'].to_s,
      company_url: company_details['URL'].to_s
    }
    @summary_json[company_details[:company_name]] = {}
    json_scrape = {}

    # STEP 2.1: Get company_url
    resp = CompanyUrlService.new(company_details: company_details).url
    @summary_json[company_details[:company_name]].merge!(resp[:summary])
    company_details.merge!({ company_url: resp[:company_url] })

    if !(company_details[:company_url].nil? || company_details[:company_url].empty?)
      # STEP 2.2: Scrape company_url
      scraped_company_url = ScrapeCompanyUrlService.new(company_details: company_details)

      # STEP 2.3: Scrape homepage content
      resp = HomepageService.new(company_details: company_details,
                                 scraped_company_url: scraped_company_url).homepage_content
      @summary_json[company_details[:company_name]].merge!(resp[:summary])
      json_scrape.merge!({ 'homepage' => resp[:homepage_content] }) if resp[:homepage_content]&.length&.positive?

      # STEP 2.4: Scrape about us URLs
      # STEP 2.5: Scrape about us content
      resp = AboutUsService.new(company_details: company_details,
                                scraped_company_url: scraped_company_url).about_us_content
      @summary_json[company_details[:company_name]].merge!(resp[:summary])
      json_scrape.merge!({ 'about_us' => resp[:about_us_content] }) if resp[:about_us_content]&.length&.positive?

      # STEP 2.6: Scrape press URLs
      # STEP 2.7: Scrape press content
      resp = PressReleasesService.new(company_details: company_details,
                                      scraped_company_url: scraped_company_url).press_releases
      @summary_json[company_details[:company_name]].merge!(resp[:summary])
      json_scrape.merge!({ 'press_releases' => resp[:press_releases] }) if resp[:press_releases]&.length&.positive?

      # STEP 2.8: News content from google search
      resp = NewsContentservice.new(company_details: company_details,
                                    scraped_company_url: scraped_company_url).news_content
      @summary_json[company_details[:company_name]].merge!(resp[:summary])
      json_scrape.merge!({ 'news_content' => resp[:news_content] }) if resp[:news_content]&.length&.positive?


      # STEP 2.9: Job details from jobspikr
      # resp = JobListingsService.new(company_details: company_details,
      #                               scraped_company_url: scraped_company_url).job_listings
      # @summary_json[company_details[:company_name]].merge!(resp[:summary])
      # json_scrape.merge!({ 'job_listings' => resp[:job_listings] }) if resp[:job_listings]&.length&.positive?

      # STEP 3: Update Database
      resp = DbConnectionService.new(company_details: company_details,
                                     json_scrape: json_scrape).update_company_and_company_scrape
      @summary_json[company_details[:company_name]].merge!(resp[:summary])
    end

    
    @log.error("********************** ENDS COMPANY SCRAPE PROCESS **************************\n\n\n\n\n")
  end
end

# Trigger
CompaniesScraping.new
