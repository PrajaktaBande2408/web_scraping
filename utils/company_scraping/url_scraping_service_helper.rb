# frozen_string_literal: true

# Module to scrape actual URLs
module UrlScrapingServiceHelper
  def uri_parse(url: '')
    URI.parse(url)
  rescue StandardError => e
    failure_response('uri_parse', url, e.message, 'URIParse')
  end

  def open_uri(uri = nil)
    uri.open(allow_redirections: :all)
  rescue StandardError => e
    failure_response('open_uri', '', e.message, 'OpenURI')
  end

  def nokogiri_html(open_page = nil)
    Nokogiri::HTML(open_page)
  rescue StandardError => e
    failure_response('nokogiri_html', '', e.message, 'NokogiriHTML')
  end

  # Some of urls like "/about-us.html" hence adding the company domain to form valid url
  # Ex:"https://www.aldoshoes.in" +  "/about-us.htm"
  def form_valid_url(url = '')
    begin
      uri = URI.parse(url)
      url = @company_domain + url if uri.scheme.nil?
    rescue StandardError => e
      url = ''
      failure_response('form_valid_url', url, e.message, 'FormValidURL')
    end
    url
  end

  def failure_response(method_name, url, exception_message, err_type)
    # Adding Exceptions to logs CSV
    csv_inputs = {
      company_name: @company_name,
      err_service: 'URL_SCRAPING_SERVICE',
      trigger: @trigger,
      err_type: err_type,
      err_message: "Exception for: #{method_name}, company: #{@company_name}, url: #{url}, #{exception_message} ",
    }
    @log.csv_logs(opts: csv_inputs)
    @log.error("Exception for: #{method_name}, company: #{@company_name}, url: #{url}, #{exception_message} ")
  end
end
