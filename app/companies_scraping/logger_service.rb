# frozen_string_literal: true

require_relative 'application'

# Class for logging all required files for debugging
class LoggerService
  include FileHelper

  def error(message)
    puts message
    open_file('../tmp/company_scraping', 'all_terminal.txt', 'a+').puts "#{message}\n"
  end

  def clear_logs
    delete_file('../tmp/company_scraping', 'all_terminal.txt')
    delete_file('../tmp/company_scraping', 'all_logs.csv')
    delete_file('../tmp/company_scraping', 'all_urls.csv')
    delete_dir('../tmp/company_scraping')
  end

  def csv_logs(opts: {})
    row_details = [
      opts[:company_name].to_s,
      opts[:err_service].to_s,
      opts[:trigger].to_s,
      opts[:err_type].to_s,
      opts[:err_message].to_s
    ]
    headers = %w[COMPANY_NAME SERVICE TRIGGER ERR_TYPE ERR_MESSAGE]

    CSV.open(valid_target_path('../tmp/company_scraping', 'all_logs.csv'), 'a+') do |csv|
      csv << headers if csv.count.eql? 0
      csv << row_details
    end
  end

  def copy_urls(opts: {})
    headers = %w[COMPANY_NAME URL_TYPE URL]

    CSV.open(valid_target_path('../tmp/company_scraping', 'all_urls.csv'), 'a+') do |csv|
      csv << headers if csv.count.eql? 0
      opts[:final_valid_urls].uniq.each do |url|
        csv << [opts[:company_name], opts[:url_type], url]
      end
    end
  end
end
