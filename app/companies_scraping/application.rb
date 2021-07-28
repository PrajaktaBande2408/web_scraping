# frozen_string_literal: true

require 'dotenv'
Dotenv.load('../../.env')
require 'logger'
require 'pry'
require 'csv'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'open_uri_redirections'
require 'rest-client'
require 'fileutils'
require 'date'


require '../../utils/file_helper'
require '../../utils/company_scraping/common_helper'
require_relative 'logger_service'
require_relative 'api_integrations_service'
require_relative 'collect_company_list_service'
require_relative 'company_url_service'
require_relative 'scrape_company_url_service'
require_relative 'url_scraping_service'
require_relative 'homepage_service'
require_relative 'about_us_service'
require_relative 'press_releases_service'
require_relative 'news_content_service'
require_relative 'google_search_api_service'
require_relative 'db_connection_service'
require_relative 'summary_service'
require_relative 'job_listings_service'
require_relative 'jobspikr_api_service'

