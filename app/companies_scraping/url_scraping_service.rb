# frozen_string_literal: true

require_relative 'application'
require '../../utils/company_scraping/url_scraping_service_helper'

# Class for Scraping urls
class UrlScrapingService
  include UrlScrapingServiceHelper
  include CommonHelper

  DROP_URLS_KEYWORDS = %w[mail pdf docs files].freeze

  def initialize(company_details: {}, trigger: nil)
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @company_domain = set_domain
    @url = form_valid_url(company_details[:url])
    @trigger = trigger
  end

  def set_domain
    uri = uri_parse(url: @company_url)
    # Example: some of urls like "/about-us.htm" hence we need to prepend company domain before starting
    uri ? "#{uri.scheme}://#{uri.hostname}" : ''
  end

  def scrape_page
    @log.error("Started url scraping: #{@url}")
    return nil if invalid_url(@url)
    # page html with open uri
    uri = uri_parse(url: @url)
    open_page = uri && open_uri(uri)
    page = open_page && nokogiri_html(open_page)

    #If open uri fails scraping page from scraper API
    if page.nil?
      page = html_from_scraper_api
    end
    page
  end

  def html_from_scraper_api
    @log.error("scraping html page with scraper API ")
    begin
      response = RestClient::Request.execute(
        method: 'GET',
        url: "http://api.scraperapi.com?api_key=#{ENV.fetch('SCRAPER_API_KEY')}&url=#{@url}"
      )
      Nokogiri::HTML(response.body)
    rescue StandardError => e
      @log.error("Exception for html_from_scraper_api")
    end
  end

  def invalid_url(url)
    matched_data = nil
    DROP_URLS_KEYWORDS.each do |keyword|
      matched_data = alpha_numeric_string(url).match(keyword)
      break if matched_data
    end
    matched_data
  end
end
