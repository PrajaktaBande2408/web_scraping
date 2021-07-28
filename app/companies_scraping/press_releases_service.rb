# frozen_string_literal: true

require_relative 'application'
# Class for Scraping Press releases content
# STEP 1: scrape company url if scraped_company_url is nil
# STEP 2: collect press urls
# STEP 3: collect press releases from press urls
# STEP 5: return press_releases and summary
#   press_urls_found: true/false
#   press_summary_found: true/false
#   press_releases_found: false

class PressReleasesService
  include CommonHelper

  URL_MATCH_KEYWORDS = %w[press news announce latestposts].freeze
  INNER_TEXT_MATCH_KEYWORDS = %w[press news announce].freeze
  EXACT_MATCH_KEYWORDS = %w[aboutprnewswire accountingnewsissues allmultimedia allnewreleases allnews allnewsreleases
                            browsenewsreleases inthenews latestarticle latestnews latestposts news newsevents newsmedia newspress newsupdates newsinfocus newsreleases newsreleasesoverview newsletters newsroom press presspartnerships presscontacts pressinquiries presskit pressrelease productupdates pressreviews companynews mediarooms].freeze
  BLOG_URL_MATCH_KEYWORDS = %w[press news announce latestposts blog].freeze
  BLOG_INNER_TEXT_MATCH_KEYWORDS = %w[press news announce blog].freeze
  LINKS_KEYWORDS_EXACT_MATCH = %w[readmore learnmore readarticle seearticle readnews].freeze

  def initialize(company_details: {}, scraped_company_url: nil)
    @log = LoggerService.new
    @company_name = company_details[:company_name]
    @company_url = company_details[:company_url]
    @summary_hash = {
      press_urls_found: false,
      press_summary_found: false,
      press_releases_found: false
    }
    @company_scraped_page = scraped_company_url.company_page || ScrapeCompanyUrlService.new(company_details: company_details).company_page
    @press_urls = []
    @press_releases = []
  end

  def press_releases
    @log.error('------ Begin PressReleasesService ------')
    @press_urls = scrape_press_urls
    @press_releases = collect_press_releases
    @log.error("------ Ends PressReleasesService ------\n\n")
    { press_urls: @press_urls, press_releases: @press_releases, summary: @summary_hash }
  end

  # PRESS  URLS
  def scrape_press_urls
    @log.error('-- started scrape_press_urls --')
    final_valid_urls = []
    # Scrape company url
    final_valid_urls = filter_links_by_keyword_match(page: @company_scraped_page)
    final_valid_urls = uniq_arr(final_valid_urls)

    update_urls_summary(final_valid_urls)

    @log.error('-- Ends scrape_press_urls --')
    final_valid_urls
  end

  def filter_links_by_keyword_match(page: nil)
    return [] if page.nil?

    nodeset = page&.xpath('//a')
    return [] if nodeset.empty?

    links = []
    # Filtering all links with keyword match algorithm
    pattern_hash = { 'pattern1' => [], 'pattern2' => [], 'pattern3' => [] }
    nodeset&.each do |element|
      inner_text = element&.children&.inner_text
      if inner_text && exact_text_match(inner_text, EXACT_MATCH_KEYWORDS)
        pattern_hash['pattern1'].push(element['href'])
      elsif pattern_hash['pattern1'].length <= 0 && contains_keyword(element['href'],
                                                                     URL_MATCH_KEYWORDS) && (inner_text && contains_keyword(
                                                                       inner_text, INNER_TEXT_MATCH_KEYWORDS
                                                                     ))
        pattern_hash['pattern2'].push(element['href'])
      elsif pattern_hash['pattern1'].length <= 0 && pattern_hash['pattern2'].length <= 0 && pattern_hash['pattern3'].length <= 0 && contains_keyword(
        element['href'], BLOG_URL_MATCH_KEYWORDS
      ) && (inner_text && contains_keyword(inner_text,
                                           BLOG_INNER_TEXT_MATCH_KEYWORDS))
        pattern_hash['pattern3'].push(element['href'])
      end
    end

    links = if pattern_hash['pattern1']&.length&.positive?
              pattern_hash['pattern1']
            elsif pattern_hash['pattern2']&.length&.positive?
              pattern_hash['pattern2']
            else
              pattern_hash['pattern3']
            end

    uniq_arr(links)
  end

  def update_urls_summary(final_valid_urls)
    if final_valid_urls&.length&.positive?
      @summary_hash[:press_urls_found] = true
      # Copy about_us Urls to CSV
      csv_inputs = {
        final_valid_urls: final_valid_urls,
        company_name: @company_name,
        url_type: 'PRESS'
      }
      @log.copy_urls(opts: csv_inputs)
    else
      csv_inputs = {
        company_name: @company_name,
        trigger: 'scrape_press_urls',
        err_message: 'Press URLs not found',
        err_type: 'press_urls_not_found',
        err_service: 'PRESS_RELEASES_SERVICE'
      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('Press URLs not found')
    end
    @log.error("final_valid_urls : #{final_valid_urls}")
  end

  # # PRESS CONTENT
  def collect_press_releases
    @log.error('-- started collect_press_releases --')
    return [] unless @press_urls&.length&.positive?

    content_arr = []
    uniq_arr(@press_urls).each do |url|
      content_arr.push(scrape_press_content(url))
    end

    content_arr = uniq_arr(content_arr)
    update_content_summary(content_arr)
    @log.error('-- Ends collect_press_releases --')
    content_arr
  end

  def scrape_press_content(url)
    @log.error('-- started scrape_press_content --')
    scraped_page = url_scraped_page(url, 'scrape_press_content')
    return [] if scraped_page.nil?

    temp_tag_hash = {}
    summary = []
    press_links_word_count_algo = []
    press_links_keyword_algo_arr = []
    press_releases = []

    # step 1: collect summary of presss page
    summary = text_scrape(scraped_page)

    # step 2
    scraped_page.search('*').each do |tag|
      next unless include_tags(%w[a], tag)

      # Searching a links with more than 10 word count
      # press_links_word_count_algo = [{date, headline, href }]
      press_links_word_count_algo.push(press_links_word_count_algo(tag))
    end

    # step 3
    unless uniq_arr(press_links_word_count_algo).length.positive?
      scraped_page.search('*').each do |tag|
        next unless include_tags(%w[a], tag)

        # Searching a links with keywords such as"read more, learnmore etc"
        # press_links_keyword_algo_arr = [{date, headline, href }]
        press_links_keyword_algo_arr.push(press_links_keyword_algo(tag))
      end
    end

    # step 4 fetch content from third urls
    uniq_arr(press_links_word_count_algo + press_links_keyword_algo_arr).each do |json|
      # scrape destination page url
      json.merge!(content: scrape_destination_url(json[:href]))
      press_releases.push(json)
    end

    # step 5 return
    {
      summary: summary,
      press_links: press_releases
    }
  end

  def press_links_word_count_algo(tag)
    inner_text = strip_string(string: tag&.children&.inner_text)
    if check_word_count(text: inner_text, minimum_word_count: 10)
      json = {
        headline: inner_text,
        href: tag['href'],
        # TO DO
        date: get_date(tag)
      }
    end
    json
  end

  def press_links_keyword_algo(tag)
    inner_text = strip_string(string: tag&.children&.inner_text)
    if exact_text_match(inner_text, LINKS_KEYWORDS_EXACT_MATCH)
      json = {
        headline: get_headline(tag),
        href: tag['href'],
        date: get_date(tag)
      }
    end
    json
  end

  # TO DO
  def get_date(_tag)
    ''
  end

  def get_headline(tag)
    headline_arr = []
    tag.parent.children.each do |c|
      text = tag_text(c)
      headline_arr.push({ text: text, length: text.split(' ')&.length }) if check_word_count(text: text,
                                                                                             minimum_word_count: 10)
    end

    new_arr = headline_arr&.sort_by! { |hsh| hsh[:length] }.reverse!
    if new_arr.length.positive?
      new_arr[0][:text].to_s || ''
    else
      ''
    end
  end

  def scrape_destination_url(url)
    scraped_page = url_scraped_page(url, 'scrape_destination_url')
    return [] if scraped_page.nil?

    text_scrape(scraped_page)
  end

  def update_content_summary(content_arr)
    summary_present = false
    content_arr.each do |json|
      if json[:summary].length.positive?
        summary_present = true
        break
      end
    end

    links_present = false
    content_arr.each do |json|
      if json[:press_links].length.positive?
        links_present = true
        break
      end
    end

    # Logs Error if no about us content found for company
    if content_arr.length <= 0
      csv_inputs = {
        company_name: @company_name,
        trigger: 'collect_press_releases',
        err_message: 'Press releases not found',
        err_type: 'press_releases_not_found',
        err_service: 'PRESS_RELEASES_SERVICE'
      }
      @log.csv_logs(opts: csv_inputs)
      @log.error('Press releases not found')
    else
      @summary_hash[:press_summary_found] = summary_present
      @summary_hash[:press_releases_found] = links_present
    end
  end
end
