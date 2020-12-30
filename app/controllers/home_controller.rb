class HomeController < ApplicationController
  require 'httparty'
  require 'json'
  require 'bootstrap-table-rails'
  def index
  	@api = StockQuote::Stock.new(api_key: 'pk_34bbabe4cf054befa331a42b695e75b2')
    @tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
    @baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"

    
  	
  	if params[:ticker] == ""
  		@nothing = "Hey, You forgot to enter a symbol"
  	elsif params[:ticker]

    	begin
  		    @stock = StockQuote::Stock.quote(params[:ticker])
          if @stock
            #OptionsStragizerJob.perform_later(@stock.symbol)
            #get_option_expirydates(ticker: @stock.symbol)
          else
            p "Stock array is empty"
          end
  		rescue StandardError, NameError, NoMethodError, RuntimeError => e
  		    @error =  "Hey, we had a problem finding data for that stock. Please try again"
          p "Rescued: #{e.inspect}"
          p e.backtrace
  		else
  		    p "No error"	 
    	ensure
    			p "Done"	    
  		end

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

  def calculate_call_debit_spreads
    #Bullish

  end

  def calculate_call_credit_spreads
    #Bearish

  end

  def calculate_put_debit_spreads
    #Bearish

  end

  def calculate_put_credit_spreads
    #Bullish

  end




  

end
