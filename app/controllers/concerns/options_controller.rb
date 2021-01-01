class OptionsController < ApplicationController
	require 'httparty'
  	require 'json'
  	require 'bootstrap-table-rails'



  	def index
  		
  		@tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
    	@baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"

  		@universes = Universe.pluck(:displaysymbol)
  		OptionsStragizerJob.perform_later

  	end


  	def show


  	end







end