class HomeController < ApplicationController


  require 'httparty'
  require 'json'
  require 'bootstrap-table-rails'
  require 'livequotetradier'
  require 'optionexpirydates'
  require 'optionchains'
  require 'calculatespreads'
  require 'logusersearch'

  def index
    
    #test jobs on load
    #StockquoteDownloadJob.perform_later("delete_all_options")
    #OptionsGetterJob.perform_later("get")
    #OptionsGetterJob.perform_later("calculate_spreads")
    #OptionsStragizerJob.perform_later("delete_old_option_spreads")
    #OptionsGetterJob.perform_later("calculate_put_sells")


  	@api = StockQuote::Stock.new(api_key: 'pk_34bbabe4cf054befa331a42b695e75b2')
    @tradier_api_key = ENV['tradier_api_key']
    @baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"
    #@universes = Universe.all
    @symbolsplucked  = Universe.pluck(:displaysymbol)
    
  	if params[:ticker] == ""
  		@nothing = "Hey, You forgot to enter a symbol"
  	elsif params[:ticker]
      _symbol = params[:ticker]
      _symbol = _symbol.upcase
      _symbol = _symbol.strip
      
      begin 
        if current_user
          usersearch = Logusersearch.new(_symbol, current_user.email)

        else
          usersearch = Logusersearch.new(_symbol, "")

        end
      rescue StandardError, NameError, NoMethodError, RuntimeError => e
          p "Rescued: #{e.inspect}"
      end
    	
      begin
  		    #_stock = StockQuote::Stock.quote(_symbol) # to validate if stock symbol is valid
          #if _stock

          #if !(@universes.select{ |u| u['displaysymbol'] == _symbol }).empty?
          _stock = StockQuote::Stock.quote(_symbol)
          if _stock
            redirect_to home_path(_symbol)
            #OptionsStragizerJob.perform_later(@stock.symbol)
            #get_option_expirydates(ticker: @stock.symbol)
          else
            p "Stock array is empty"
            @error =  "Hey, we had a problem finding data for that stock. Please try another stock."
          end
  		rescue StandardError, NameError, NoMethodError, RuntimeError => e
  		    @error =  "Hey, we had a problem finding data for that stock. Please try again."
          p "Rescued: #{e.inspect}"
          p e.backtrace
  		else
  		    p "No error"	 
    	ensure
    			p "Done"	    
  		end

  	end
  end

  def show
    require 'uri'
    require 'net/http'
    @stock = params[:id] 
    @tradier_api_key = ENV['tradier_api_key']
    @baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"
    @recommendations = Recommendation.all
    if current_user
      @currentUser = current_user.id
      @bookmarks = Optionbookmark.select{ |o| o['user_id']==current_user.id}
    end

    begin
      @ticker = Livequotetradier.new(@stock)
      @ticker_logo  = (StockQuote::Stock.logo(@stock)).url
      if !@ticker
        p "ticker could not be fetched using tradier api"
        @ticker = StockQuote::Stock.quote(@stock)
      end
      if @ticker
        #Get expiry date of options with API
        options_e_dates = Optionexpirydates.new(@ticker.symbol)
        @expirydates_data = options_e_dates.e_dates

        cached_optionchain_result(@ticker.symbol, @expirydates_data)
       
      end
    rescue StandardError, NameError, NoMethodError, RuntimeError => e
      p "Rescued: #{e.inspect}"
      p e.backtrace
      @ticker = nil
    else
    ensure
    end  
  end

  def about
  end

  def get_option_expirydates(ticker:)
      begin 
        url_options_expiry_string = @baseurl_tradier + "options/expirations?symbol=" + ticker + "&includeAllRoots=true&strikes=false"
        response = HTTParty.get(url_options_expiry_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})

        expirydates_data = Array[]

        if response.code == 200
          if response.parsed_response['expirations']
            expirydates_data = response.parsed_response['expirations']['date']
          end
        end
        
        if !expirydates_data.empty?
          if expirydates_data.kind_of?(Array) 
            expirydates_data.each do |item|
              #@queue.shift # rate limiter block
              getoptionchains_apicall(symbol: ticker, expirydate: item)
            end
          else
              #p "Non array expiry date response for " + (security['displaysymbol']).to_s + (expirydates_data).to_s
              getoptionchains_apicall(symbol: ticker, expirydate: expirydates_data.to_s )
          end
        end
      rescue StandardError, NameError, NoMethodError, RuntimeError => e
        p "Rescued: #{e.inspect}"
        p e.backtrace

      else

      ensure

      end

  end

  def getoptionchains_apicall(symbol:, expirydate:)

      begin 
          #api call to tradier to fetch option chains for a selected expiry date
        url_options_chain_string = @baseurl_tradier + "options/chains?symbol=" + symbol + "&expiration=" + expirydate + "&greeks=true"
      response = HTTParty.get(url_options_chain_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})
      

      if response.code == 200 #valid response
        if response.parsed_response['options']['option']
          @optionchain_data = response.parsed_response['options']['option']
          if !@optionchain_data.empty?
            #p @optionchain_data
              @status_option = "done"

          end

        end
      end
    
    rescue StandardError, NameError, NoMethodError, RuntimeError => e
      p "Error for " + symbol + " exp date " + expirydate.to_s
      #p response
      p "Rescued: #{e.inspect}"
      #p e.backtrace
    else

    ensure

    end

  end

  def calculate_spreads
    #Calculate Spreads
    symbol = params[:symbol]
    latest_price = params[:latest_price]
    @expirydates_data = params[:expirydates_data]
    optionchains_data = cached_optionchain_result(symbol, @expirydates_data)
    @strategy = params[:strategy]
    @target = params[:target]
    jump = params[:jump]
    maxrisk = params[:maxrisk]
    minreward = params[:minreward]
    minrr = params[:minrr]
 
    
    #calc spreads
    _spreads = Calculatespreads.new(optionchains_data, latest_price, symbol, @expirydates_data, @strategy, @target, jump, maxrisk, minreward, minrr)
    @spreads = _spreads.analysis_results
    
    respond_to do |format|
        format.js
    end
    
    
  end

  def load_roi_visualizer
   symbol = params[:symbol]
    quote = params[:quote]
    e_date = params[:e_date]
    long_iv = params[:long_iv]
    short_iv = params[:short_iv]
    dividend = params[:dividend]
    long_strike = params[:long_strike]
    short_strike = params[:short_strike]
    strategy = params[:strategy]
    entry_cost = params[:entry_cost]

    bs = Blackscholesprocessor.new(symbol, quote, e_date, long_iv, short_iv, dividend, long_strike, short_strike, strategy, entry_cost)
    @_price_grid =(bs.price_grid)
    @price_grid = (@_price_grid)
    @strikes = (bs.strikes_array)
    @days = (bs.days_array)
    @labeled_months = (bs.labeled_months_array)
    @labeled_dates = (bs.labeled_dates_array)
    @current_quote = quote


    respond_to do |format|
        format.js 
    end
    
    #get_roi_json(@_price_grid.to_json)

  end

  def cached_optionchain_result(symbol, expirydate)
    Rails.cache.fetch([symbol, :cached_optionchain_result], expires_in: 30.minutes) do
        # Only executed if the cache does not already have a value for this key
        puts "Making API Call to get option chains..."
        #Get option chains with API
        _optionchains = Optionchains.new(symbol, expirydate)
        @optionchains_data = _optionchains.chains
    end
  end


 

end
