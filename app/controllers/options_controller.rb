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
      @Optionputsells_count = Optionputsell.pluck(:id).count

  		#OptionsStragizerJob.perform_later("calc_top_option_spreads")
      #StockquoteDownloadJob.perform_later("refresh_options")
      #OptionsStragizerJob.perform_later("calc_op_spreads")
      #StockquoteDownloadJob.perform_later("get_targets_largecap")
      #StockquoteDownloadJob.perform_later("earningscalendar")

      #p @optionchains


      #@high_open_interest = Optionhighopeninterest.all
    
      @best_sp_options = Optionputsell.find_by_sql(
              "SELECT
                 *
               FROM optionputsells
               WHERE optionputsells.premiumratio>0.01 
               and (optionputsells.strike / optionputsells.quote) <= 0.9
               ORDER BY optionputsells.premiumratio DESC, 
               (optionputsells.strike / optionputsells.quote) ASC
               LIMIT 2000
               "
               )

      @best_rr_options = Optionscenario.find_by_sql(
              "SELECT
                 *
               FROM optionscenarios
               WHERE optionscenarios.rr_ratio>1 
               and optionscenarios.risk<500 
               and optionscenarios.risk>25 
               and optionscenarios.reward>50 
               and optionscenarios.perc_change<20
               ORDER BY optionscenarios.rr_ratio DESC, optionscenarios.perc_change ASC 
               LIMIT 1000
               "
               )


      
    end

  	def show


  	end

end