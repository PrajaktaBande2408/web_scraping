# frozen_string_literal: true

require_relative 'application'
# Class for Scraping About Us content
# STEP 1: scrape company url if scraped_company_url is nil
# STEP 2: collect about us urls
# STEP 3: scrape about us urls second loop
# STEP 4: collect about content from about us urls
# STEP 5: return about_us_content and summary
#   about_us_url_found: true/false
#   about_us_content_found

class AboutUsService
  include CommonHelper

  URL_MATCH_KEYWORDS = %w[about aboutus corporate corporateinformation whoweare why companybackground history ourstory
                          ourorganization]
  INNER_TEXT_MATCH_KEYWORDS = %w[about aboutus corporate corporateinformation whoweare why companybackground history
                                 ourstory ourorganization]
  EXACT_MATCH_KEYWORDS = %w[aboutus corporateinformation whoweare companybackground ourstory
                            ourorganization]

  def initialize(company_details: {}, scraped_company_url: nil)
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @summary_hash = { about_us_url_found: false, about_us_content_found: false }
    @company_scraped_page = scraped_company_url.company_page || ScrapeCompanyUrlService.new(company_details: company_details).company_page
    update_constants
    @about_us_urls = []
    @about_us_content = []
  end

  def update_constants
    INNER_TEXT_MATCH_KEYWORDS.push(alpha_numeric_string(@company_name))
    EXACT_MATCH_KEYWORDS.push(alpha_numeric_string("about#{@company_name}"))
  end

  def about_us_content
    @log.error('------ Begin AboutUsService ------')
    @about_us_urls = scrape_about_us_urls
    @about_us_content = collect_about_us_content
    @log.error("------ Ends AboutUsService ------\n\n")
    { about_us_urls: @about_us_urls, about_us_content: @about_us_content, summary: @summary_hash }
  end

  # ABOUT US URLS
  def scrape_about_us_urls
    @log.error('-- started scrape_about_us_urls --')
    temp_link_store = []
    final_valid_urls = []

    # Scrape company url
    first_level_urls = filter_links_by_keyword_match(page: @company_scraped_page)

    # Storing URLs captured in first scrape
    temp_link_store.push(first_level_urls)

    # Scraping each URL found in first scrape to get more URLs
    # Ex: Some of about urls may not be found in first step hence required nested scraping
    first_level_urls.each do |url|
      page = url_scraped_page(url, 'scrape_about_us_urls')
      temp_link_store.push(filter_links_by_keyword_match(page: page))
    end

    final_valid_urls = uniq_arr(temp_link_store)

    update_urls_summary(final_valid_urls)

    @log.error('-- Ends scrape_about_us_urls --')
    final_valid_urls
  end

  def filter_links_by_keyword_match(page: nil)
    return [] if page.nil?

    nodeset = page&.xpath('//a')
    return [] if nodeset.empty?

    links = []
    # Filtering all links with keyword match algorithm
    nodeset&.each do |element|
      inner_text = element&.children&.inner_text
      if inner_text && exact_text_match(inner_text, EXACT_MATCH_KEYWORDS)
        links.push(element['href'])
      elsif contains_keyword(element['href'],
                             URL_MATCH_KEYWORDS) && (inner_text && contains_keyword(inner_text,
                                                                                    INNER_TEXT_MATCH_KEYWORDS))
        links.push(element['href'])
      end
    end
    uniq_arr(links)
  end

  def update_urls_summary(final_valid_urls)
    if final_valid_urls&.length&.positive?
      @summary_hash[:about_us_url_found] = true
      # Copy about_us Urls to CSV
      csv_inputs = {
        final_valid_urls: final_valid_urls,
        company_name: @company_name,
        url_type: 'ABOUT_US'
      }
      @log.copy_urls(opts: csv_inputs)
    else
      csv_inputs = {
        company_name: @company_name,
        trigger: 'scrape_about_us_urls',
        err_message: 'About Us URLs not found',
        err_type: 'about_us_urls_not_found',
        err_service: 'ABOUT_US_SERVICE'

      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('About Us URLs not found')
    end
    @log.error("final_valid_urls : #{final_valid_urls}")
  end

  # ABOUT US CONTENT
  def collect_about_us_content
    @log.error('-- started scrape_about_us_content --')
    return [] unless @about_us_urls&.length&.positive?

    content_arr = []
    uniq_arr(@about_us_urls).each do |url|
      content_arr.push(scrape_about_content(url))
    end

    content_arr = uniq_arr(content_arr)
    update_content_summary(content_arr)
    @log.error('-- Ends scrape_about_us_content --')
    content_arr
  end

  def scrape_about_content(url)
    scraped_page = url_scraped_page(url, 'scrape_about_content')
    return [] if scraped_page.nil?

    text_scrape(scraped_page)
  end

  def update_content_summary(content_arr)
    # Logs Error if no about us content found for company
    if content_arr.length <= 0
      csv_inputs = {
        company_name: @company_name,
        trigger: 'scrape_about_content',
        err_message: 'About Us content not found',
        err_type: 'about_us_content_not_found',
        err_service: 'ABOUT_US_SERVICE'
      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('About Us content not found')
    else
      @summary_hash[:about_us_content_found] = true
    end
  end
end
