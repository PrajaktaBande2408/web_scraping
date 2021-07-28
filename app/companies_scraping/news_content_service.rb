# frozen_string_literal: true

require_relative 'application'
# Class for Scraping News content
# STEP 1: call Google search API to get search results
# STEP 2: loop on search results and scrape each Link
# STEP 4: collect news content from destination page
# STEP 5: return news_content and summary
#   news_gsearch_results_found: true/false
#   news_content_found: true/false
#   news_destination_content_found: true/false

class NewsContentservice
  include CommonHelper

  def initialize(company_details: {}, scraped_company_url: nil)
    @log = LoggerService.new
    @company_details = company_details
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @summary_hash = { news_gsearch_results_found: false, news_content_found: false }
    @news_content = []
    @googl_search_results = []
  end

  def news_content
    @log.error('------ Begin NewsContentservice ------')
    @googl_search_results = get_google_search_results
    @news_content = collect_news_content
    @log.error("------ Ends NewsContentservice ------\n\n")
    { news_content: @news_content, summary: @summary_hash }
  end

  def get_google_search_results
    @log.error('-- started NewsContentservice:get_google_search_results --')
    params = {
      company_details: @company_details,
      search_query: search_query,
      trigger: 'news_content'
    }
    @log.error('-- Ends NewsContentservice:get_google_search_results --')
    GoogleSearchApiService.new(params).search_results
  end

  def search_query
    "intitle:\"#{@company_name}\" AND (\"news\" OR \"press\" OR \"announce\" OR \"lanuches\" \"media\" OR \"programs\" OR \"events\") -linkedin -facebook -zoominfo -job -interview -youtube -glassdoor -wikipedia -amazon -pinterest -images -videos -twitter -shop after:2021"
  end

  def collect_news_content
    @log.error('-- started collect_news_content --')

    news_content = []
    @googl_search_results&.each do |obj|
      json = {
        "date": '',
        "href": obj['url'],
        "headline": obj['description']
      }

      json.merge!(content: scrape_news_content(obj['url']))
      news_content.push(json)
    end
    update_news_summary(news_content)
    @log.error('-- Ends collect_news_content --')
    news_content
  end

  def scrape_news_content(url)
    scraped_page = url_scraped_page(url, 'scrape_news_content')
    return [] if scraped_page.nil?

    text_scrape(scraped_page)
  end

  def update_news_summary(news_content)
    # Logs Error if no search result found found for company
    @summary_hash[:news_gsearch_results_found] = true if @googl_search_results.length.positive?

    if news_content.length <= 0
      csv_inputs = {
        company_name: @company_name,
        err_type: 'news_content_not_found',
        trigger: 'collect_news_content',
        err_message: 'News content not found',
        err_service: 'NEWS_CONTENT_SERVICE'
      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('Not_found news_content: NewsContentservice : news content not found')
    else
      news_destination_content_present = false
      news_content.each do |json|
        if json[:content].length.positive?
          news_destination_content_present = true
          break
        end
      end

      @summary_hash[:news_destination_content_found] = news_destination_content_present
      @summary_hash[:news_content_found] = true
    end
  end
end
