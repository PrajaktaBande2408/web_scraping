# frozen_string_literal: true

require_relative 'application'
# Class for Scraping Homepage content
# STEP 1: scrape company url if scraped_company_url is nil
# STEP 2: collect content from url
# STEP 3: return homepage_content and summary
#   homepage_content_found: true/false

class HomepageService
  include CommonHelper

  def initialize(company_details: {}, scraped_company_url: nil)
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @summary_hash = { homepage_content_found: true }
    @scraped_company_url = scraped_company_url || ScrapeCompanyUrlService.new(company_details: company_details)
    @homepage_content = []
  end

  def homepage_content
    @log.error('------ Begin HomepageService ------')
    @homepage_content = scrape_homepage_content
    update_summary
    @log.error("------ Ends HomepageService ------\n\n")
    { homepage_content: @homepage_content, summary: @summary_hash }
  end

  def scrape_homepage_content
    company_scraped_page = @scraped_company_url.company_page
    return [] if company_scraped_page.nil?

    text_scrape(company_scraped_page)
  end

  def update_summary
    unless @homepage_content&.length&.positive?
      @summary_hash[:homepage_content_found] = false
      csv_inputs = {
        company_name: @company_name,
        trigger: 'HomepageService',
        err_message: 'Homepage content not found',
        err_type: 'homepage_content_not_found',
        err_service: 'HOMEPAGE_SERVICE'
      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('Homepage content not found')
    end
  end
end
