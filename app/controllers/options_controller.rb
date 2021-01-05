class OptionsController < ApplicationController
	require 'httparty'
  	require 'json'
  	require 'bootstrap-table-rails'



  	def index
  		
  		@tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
    	@baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"

  		@universes = Universe.pluck(:displaysymbol)
      #@optionchain_count = Optionchain.pluck(:symbol).count
      @Optionscenario_count = Optionscenario.pluck(:id).count

  		#OptionsStragizerJob.perform_later("calc_top_option_spreads")
      #StockquoteDownloadJob.perform_later("refresh_options")
      #OptionsStragizerJob.perform_later("calc_op_spreads")
      #StockquoteDownloadJob.perform_later("get_targets_largecap")
      #StockquoteDownloadJob.perform_later("earningscalendar")

      #p @optionchains


      @high_open_interest = Optionhighopeninterest.all
      @best_rr_options = Topoptionscenario.all
    end

  	def show


  	end

end