# frozen_string_literal: true
require_relative '../../app/companies_scraping/application'
RSpec.describe 'AboutUsService' do
  context '#initialize' do
    before(:example) do
      @company_details = {
        company_url: "test_company_url",
        company_name: "Test",
        scraped_company_url: "scraped_page"
      }
    end

    it 'should set LoggerService' do
      expect_any_instance_of(LoggerService).to receive(:initialize).exactly(1).times
      AboutUsService.new(company_details: @company_details)
    end

    # it 'should set company_name, company_url' do
    # end

    # it 'should expect ScrapeCompanyUrlService if scraped_company_url id nil' do
    # end

    # it 'should expect update_constants' do
    # end
  end


end
