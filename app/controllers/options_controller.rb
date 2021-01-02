class OptionsController < ApplicationController
	require 'httparty'
  	require 'json'
  	require 'bootstrap-table-rails'



  	def index
  		
  		@tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
    	@baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"

  		@universes = Universe.pluck(:displaysymbol)
      @optionchain_count = Optionchain.pluck(:symbol).count
      @Optionscenario_count = Optionscenario.pluck(:id).count

  		#OptionsStragizerJob.perform_later
      #StockquoteDownloadJob.perform_later("refresh_options")

      #p @optionchains
      

      @high_open_interest = Optionhighopeninterest.all
      @best_rr_options = Optionscenario.select{ |o| o['perc_change']<35 }.group_by { |r| r["rr_ratio"] }.sort_by  { |k, v| -k }.first(500).map(&:last).flatten
      
    end

  	def show


  	end

end