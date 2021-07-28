# frozen_string_literal: true

require_relative 'application'
require '../../utils/company_scraping/company_url_service_helper'
# Class for Scraping company_url

class ScrapeCompanyUrlService
  include CompanyUrlServiceHelper

  def initialize(company_details: {})
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @page = nil
    scrape_company_url
  end

  def scrape_company_url
    @log.error('------ Begin ScrapeCompanyUrlService ------')
    @log.error("Starte scraping company url for:#{@company_name} : #{@company_url}")
    params = {
      company_details: {
        company_name: @company_name,
        company_url: @company_url,
        url: @company_url
      },
      trigger: 'scrape_company_url'
    }
    @page = UrlScrapingService.new(params).scrape_page
    @log.error("------ Ends ScrapeCompanyUrlService ------\n\n")
  end

  def company_page
    @page
  end
end
