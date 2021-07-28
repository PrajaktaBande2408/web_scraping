# frozen_string_literal: true

require_relative 'application'

# Class for collecting company list
class CollectCompanyListService
  include FileHelper
  COMPANY_NAMES_CSV = 'company_names_127.csv'

  def initialize
    @log = LoggerService.new
    @environment = ENV.fetch('ENVIRONMENT')
  end

  def collect_companies_list
    @log.error('------ Begin CollectCompanyListService ------')

    company_list = case @environment
                   when 'production' then collect_company_list_from_api
                   when ('development' || 'test') then collect_company_list_from_csv
                   end

    @log.error("------ Ends CollectCompanyListService ------\n\n")
    company_list
  end

  def collect_company_list_from_api
    @log.error('collecting company list from API')

    opts = {
      payload: { 'name' => '', 'client_codes' => [] },
      method: 'POST',
      url: 'v1/company-list-get',
      company_name: 'ALL Companies',
      trigger: 'collect_company_list_from_api'
    }

    resp = ApiIntegrationsService.new(opts: opts).call
    resp[:success] ? format_company_list_response(resp[:resp_body]) : []
  end

  def collect_company_list_from_csv
    @log.error('collecting company list from CSV')
    csv_text = read_file('../assets', COMPANY_NAMES_CSV)
    company_arr = []
    csv = CSV.parse(csv_text, headers: true)
    csv.each do |row|
      company_arr.push({ 'company_name' => row[0], 'URL' => row[1] || '' })
    end
    company_arr
  end

  def format_company_list_response(resp_body)
    company_arr = []
    resp_body['payload']&.each do |company|
      cmp_hash = {
        'company_name' => company['name'] || '',
        'URL' => company['company_url'] || ''
      }
      company_arr.push(cmp_hash)
    end
    company_arr
  end
end
