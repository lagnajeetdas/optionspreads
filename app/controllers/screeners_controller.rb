class ScreenersController < ApplicationController
	require 'httparty'
  	require 'json'
  	require 'bootstrap-table-rails'

  	def index
  		@stockprofiles = Stockprofile.where(marketcap_type: "Large Cap")
  		@stockprices = Stockprice.all
  		@universes = Universe.all
  		@universes_pluck = Universe.pluck(:displaysymbol)

  		@sp1 = @stockprofiles.merge(@stockprices)

  	end

  	def show

  	end



end