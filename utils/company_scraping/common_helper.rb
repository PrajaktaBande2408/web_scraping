# frozen_string_literal: true

# module for common helper fetching methods
module CommonHelper
  def uniq_arr(arr)
    arr&.flatten&.uniq&.reject { |x| x.nil? || x.empty? }
  end

  def include_tags(valid_tags, tag)
    valid_tags.include? tag&.name
  end

  def tag_text(tag)
    strip_string(string: tag&.text)
  end

  def strip_string(string: '')
    if !string.valid_encoding?
      string.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')&.gsub(/\s+/, ' ')&.gsub("'", '')
    else
      string&.strip&.gsub(/\s+/, ' ')&.gsub("'", '')
    end
  end

  def check_word_count(text: '', minimum_word_count: 15)
    text.split(' ').length > minimum_word_count
  end

  def priortise_tag_base_content(valid_tags, tags_content)
    arr = []
    valid_tags.each do |tag|
      temp_arr = uniq_arr(tags_content[tag])
      next unless (tags_content.keys.include? tag) && temp_arr&.length&.positive?

      arr = temp_arr
      break
    end

    arr
  end

  def contains_keyword(string, keywrods)
    return false if string.nil? || string.empty?

    string = alpha_numeric_string(string)
    matched_data = nil
    keywrods.each do |keywrod|
      matched_data = string.match(keywrod)
      break if matched_data
    end
    matched_data
  end

  def exact_text_match(string, keywrods)
    return false if string.nil? || string.empty?

    string = alpha_numeric_string(string)
    keywrods.include? string
  end

  def alpha_numeric_string(string)
    string.downcase.gsub(/[^0-9A-Za-z]/, '')
  end

  def url_scraped_page(url, trigger)
    params = {
      company_details: {
        company_name: @company_name,
        company_url: @company_url,
        url: url
      },
      trigger: trigger
    }
    UrlScrapingService.new(params).scrape_page
  end

  def text_scrape(scraped_page)
    temp_tag_hash = {}
    valid_tags = %w[p article h6 h5 h4 h3 h2 h1 li span]

    scraped_page.search('*').each do |tag|
      next unless include_tags(valid_tags, tag) # checking valid tags

      text = tag_text(tag)
      next unless check_word_count(text: text, minimum_word_count: 15) # checking word count in sentense

      # generating hash with tags as keys and innertext as values
      if temp_tag_hash.keys.include? tag&.name
        temp_tag_hash[tag&.name].push(text)
      else
        temp_tag_hash[tag&.name] = [text]
      end
    end

    # Finalising/priortising content based on tags
    content = priortise_tag_base_content(valid_tags, temp_tag_hash)
    uniq_arr(content)
  end
end
