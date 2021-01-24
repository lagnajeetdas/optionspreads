class StockquoteDownloadJob < ApplicationJob
  queue_as :default
  extend Limiter::Mixin
  require 'acquiretarget'
  require 'earningsdate'
  
  def perform(service_name)
	    # Do something later
	    # Finnhub API base parameters
	    p "@@@@@@@@@@@@@@@@@@@@@ Background Job Initialized  @@@@@@@@@@@@@@@@@@@@"

	    @finnhub_api_key = ENV['finnhub_api_key']
	    @finnhub_api_key_prod = ENV['finnhub_api_key_prod']
	  	@finnhub_baseurl = "https://finnhub.io/api/v1/stock/symbol?"
	  	@finnhub_baseurl_2 = "https://finnhub.io/api/v1/stock/"
	  	@tradier_api_key = ENV['tradier_api_key']
    	@baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"
	  	@exchange = "US"
	  	@currency = "USD"

	  	#get models into instances
	  	@universes = Universe.all

	    #function calls
	    #getstockuniverse
	  	#getrecommendations
	  	case service_name
		  	when "universe"
		  		getstockuniverse
		  	when "recommendation"
		  		@recommendations = Recommendation.all
		  		getrecommendations
		  	when "delete_recommendations"
		  		p Recommendation.delete_all
		  	when "metadata"
		  		@stockprofiles = Stockprofile.all
		  		getstockprofiledata
		  	when "delete_stockprofiles"
		  		@stockprofiles = Stockprofile.all
		  		p Stockprofile.delete_all
		  	when "refresh_options"
		  		@optionchain_import = Array[]
		  		get_options
		  	when "clear_oldoptions"
		  		clear_old_optionchains
		  	when "delete_all_options"
		  		p Optionchain.delete_all
		  	when "download_stock_quotes"
		  		get_stock_quotes_snapshot
		  	when "get_targets_largecap"
		  		get_targets("Large Cap")
	  		when "get_targets_midcap"
		  		get_targets("Mid Cap")
	  		when "get_targets_smallcap"
		  		get_targets("Small Cap")
		  	when "earningscalendar"
		  		get_earningscalendar
		  	else
		  		p "No method found"
  end

  end

  def getstockuniverse
	  	p "@@@@@@@@@@@@@@@@@@@@@ Stocks universe download starting.... @@@@@@@@@@@@@@@@@@@@"  	
	  	# API call to get all symbols from finnhub
	  	url_finnhub_stocksuniverse = @finnhub_baseurl + "exchange=" + @exchange + "&currency=" + @currency + "&token=" + @finnhub_api_key
	  	response = HTTParty.get(url_finnhub_stocksuniverse)

	  	#procesiing response
	  	stocksuniverse_ary = Array[]
	  	recommendation_ary_stock = Array[]

	  	if response.code == 200
			stocksuniverse_ary = response.parsed_response
			# filter for MIC codes XNYS (NYSE) and XNGS (NASDAQ) stock exchanges
			stocksuniverse_ary = stocksuniverse_ary.select{ |item| item["mic"] == "XNYS" || item["mic"] == "XNGS" }
			#filter for security type - common stocks, exchange traded products, american depository receipts, REIT
			stocksuniverse_ary = stocksuniverse_ary.select{ |item| item["type"] == "Common Stock" || item["type"] == "ADR" || item["type"] == "ETP" || item["type"] == "ETN" || item["type"] == "REIT" }
	    end

	    stocksuniverse_ary.each do |item|
	    	if @universes.select{ |u| u['displaysymbol']==item['displaySymbol'] }.empty?
		    	@universe = Universe.new(currency: item['currency'], description: item['description'], displaysymbol: item['displaySymbol'], figi: item['figi'], mic: item['mic'], security_type: item['type'])
		    	if @universe.save
			      p "Saved to db " + item['displaySymbol'].to_s
			    else
			      p "Did not save to db " + item['displaySymbol'].to_s
			    end
			end
	    end

	    p "@@@@@@@@@@@@@@@@@@@@@ Stocks universe download finished. @@@@@@@@@@@@@@@@@@@@"  	
  end


  def getrecommendations
	  	p "@@@@@@@@@@@@@@@@@@@@@ Analyst recommendations download starting @@@@@@@@@@@@@@@@@@@@"  	
	    # API call to get analyst recommendations from finnhub for a given stock
	    #https://finnhub.io/api/v1/stock/recommendation?symbol=AAPL&token=bv1u7mf48v6o5ed6gpd0
	  	recommendation_ary = Array[]
	  	@universes.each do |security|
		  	url_finnhub_recommendation = @finnhub_baseurl_2 + "recommendation?symbol=" + security['displaysymbol'] + "&token=" + @finnhub_api_key
		  	response = HTTParty.get(url_finnhub_recommendation)
		  	
		  	if response.code == 200
		  		recommendation_ary_stock = response.parsed_response
		  		if !recommendation_ary_stock.empty?
		  			#recommendation_ary =  recommendation_ary.push(recommendation_ary_stock[0])
		  			if @recommendations.select{ |r| r['symbol']==security['displaysymbol'] && r['period']==recommendation_ary_stock[0]['period'] }.empty?
				    	@recommendation = Recommendation.new(buy: recommendation_ary_stock[0]['buy'], hold: recommendation_ary_stock[0]['hold'], period: recommendation_ary_stock[0]['period'], sell: recommendation_ary_stock[0]['sell'], strongbuy: recommendation_ary_stock[0]['strongBuy'], strongsell: recommendation_ary_stock[0]['strongSell'], symbol: security['displaysymbol'] )
				    	if @recommendation.save
					      p "Saved recommendation to db " + security['displaysymbol'].to_s
					    else
					      p "Did not save recommendation to db " + security['displaysymbol'].to_s
					    end
					end
		  		end
		  	end
		end

		p "@@@@@@@@@@@@@@@@@@@@@ Analyst recommendations download finished @@@@@@@@@@@@@@@@@@@@"  	
  end


  def getstockprofiledata
  	
	  	#API Call to get industry, market cap, logo
	  	p "@@@@@@@@@@@@@@@@@@@@@ Stocks meta data download starting.... @@@@@@@@@@@@@@@@@@@@"  
	  	@queue = Limiter::RateQueue.new(56, interval: 60)

	  	@universes.each do |security|
	  		if !Stockprofile.where(symbol: security['displaysymbol']).present?
		  		@queue.shift
		  		getstockprofiledata_apicall(security: security) 
		  	end
		end
		

		p "@@@@@@@@@@@@@@@@@@@@@ Stocks meta data download finished. @@@@@@@@@@@@@@@@@@@@"  
  end


  def getstockprofiledata_apicall(security:)
	  	stockprofile_ary = Array[]
	  	_marketcaptype = ""
	  	
	  	begin 
		  	if @stockprofiles.select{ |s| s['symbol']==security['displaysymbol'] }.empty?
			  	url_finnhub_stockprofile = @finnhub_baseurl_2 + "profile2?symbol=" + security['displaysymbol'] + "&token=" + @finnhub_api_key_prod
				  	response = HTTParty.get(url_finnhub_stockprofile)
				  	if response.code == 200
				  		stockprofile_ary = response.parsed_response
				  		if !stockprofile_ary.empty?
			  				#p security['displaysymbol'] 
			  				#p (stockprofile_ary['marketCapitalization'])
			  				if (stockprofile_ary['marketCapitalization']) && (stockprofile_ary['marketCapitalization'])!=""
				  				if (stockprofile_ary['marketCapitalization']).to_f < 3000.0
				  					_marketcaptype = "Small Cap"
				  				elsif (stockprofile_ary['marketCapitalization']).to_f > 10000.0
				  					_marketcaptype = "Large Cap"
				  				else
									_marketcaptype = "Mid Cap"
				  				end
				  			end
				  			#p _marketcaptype

					    	@stockprofile = Stockprofile.new(symbol: security['displaysymbol'], industry: stockprofile_ary['finnhubIndustry'], marketcap: stockprofile_ary['marketCapitalization'], logo: stockprofile_ary['logo'], marketcap_type: _marketcaptype )
					    	if @stockprofile.save
						      p "Saved stock meta data to db " + security['displaysymbol'].to_s
						    else
						      p "Did not save stock meta data to db " + security['displaysymbol'].to_s
						    end
							
				  		end
				  	end
			end

		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Rescued: #{e.inspect}"
			p e.backtrace

		else

		ensure

		end
  end


  def get_options
  	
	  	p "@@@@@@@@@@@@@@@@@@@@@ Option chain download starting.... @@@@@@@@@@@@@@@@@@@@"  


	  	@universes.each do |security|
	  		#get expiry dates of a given stock
	  		
	  			getoptionexpiry_apicall(security: security) 

		end
		

		p "@@@@@@@@@@@@@@@@@@@@@ Option chain download finished. @@@@@@@@@@@@@@@@@@@@"  

		OptionsStragizerJob.perform_later("calc_high_open_interests")
  end


  def getoptionexpiry_apicall(security:)
	  	#@queue = Limiter::RateQueue.new(118, interval: 60) # rate limiter setup
	  	@optionchain_import = Array[]
	  	begin 
		  	url_options_expiry_string = @baseurl_tradier + "options/expirations?symbol=" + security['displaysymbol'] + "&includeAllRoots=false&strikes=false"
			response = HTTParty.get(url_options_expiry_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})

			expirydates_data = Array[]

			if response.code == 200
				if response.parsed_response['expirations']
					expirydates_data = response.parsed_response['expirations']['date']
				end
			end
			
			if !expirydates_data.empty?
				if expirydates_data.kind_of?(Array)
					#delete all existing option chains for that symbol before downloading more data
					Optionchain.where(underlying: security['displaysymbol']).delete_all 
					expirydates_data.each do |item|
						#@queue.shift # rate limiter block
						getoptionchains_apicall(symbol: security['displaysymbol'], expirydate: item, universeid: security['id'])
					end
				else
						#p "Non array expiry date response for " + (security['displaysymbol']).to_s + (expirydates_data).to_s
						getoptionchains_apicall(symbol: security['displaysymbol'], expirydate: expirydates_data.to_s, universeid: security['id'] )
				end
				if !@optionchain_import.empty?
					Optionchain.import @optionchain_import
					@optionchain_import = Array[]
					#p "Saved import data to db"
				else
					p "option chain import array is empty"
				end
			end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Rescued: #{e.inspect}"
			p e.backtrace
			if !@optionchain_import.empty?
				Optionchain.import @optionchain_import
				@optionchain_import = Array[]
				p "error but successfully saved data to optionchain db"
			else
				p "option chain import array is empty"
			end
		else
			
		ensure

		end
  end


  def getoptionchains_apicall(symbol:, expirydate:, universeid:)
 		
 		begin 
 			#check if option with same symbol, expiry date exists in db with creation date within 1 hour in past
 			#if (@optionchains.select{ |oc| oc['underlying'] == symbol && oc['expiration_date'] == expirydate && ((oc['created_at']- DateTime.now)/ 3600) <=3  }).empty?
			  	
			  	#api call to tradier to fetch option chains for a selected expiry date
			  	url_options_chain_string = @baseurl_tradier + "options/chains?symbol=" + symbol + "&expiration=" + expirydate + "&greeks=true"
				response = HTTParty.get(url_options_chain_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})
				

				if response.code == 200 #valid response
					if response.parsed_response['options']['option']
						optionchain_data = response.parsed_response['options']['option']
						
						#delete existing option chains with matching symbol and expiry date
						#p Optionchain.count
						#p Optionchain.where(underlying: symbol).count
						#p Optionchain.where(underlying: symbol).where(expiration_date: expirydate).delete_all

						
						if !optionchain_data.empty?
							#then save to DB model
								optionchain_data.each do |contract_item|
									contract_item_greeks = contract_item['greeks']
									if !contract_item_greeks.nil?
										@optionchain_import.push(Optionchain.new(universe_id: universeid, symbol: (contract_item['symbol']).to_s, description: (contract_item['description']).to_s, exch: (contract_item['exch']).to_s, option_type: (contract_item['option_type']).to_s, volume: (contract_item['volume']), bid: (contract_item['bid']), ask: (contract_item['ask']), underlying: (contract_item['underlying']).to_s, strike: (contract_item['strike']), change_percentage: (contract_item['change_percentage']), average_volume: (contract_item['average_volume']), last_volume: (contract_item['last_volume']), bidsize: (contract_item['bidsize']), asksize: (contract_item['asksize']), open_interest: (contract_item['open_interest']), expiration_date: (contract_item['expiration_date']).to_s, expiration_type: (contract_item['expiration_type']).to_s, root_symbol: (contract_item['root_symbol']).to_s, bid_iv: (contract_item_greeks['bid_iv']), mid_iv: (contract_item_greeks['mid_iv']), ask_iv: (contract_item_greeks['ask_iv']) ))
									else
										@optionchain_import.push(Optionchain.new(universe_id: universeid, symbol: (contract_item['symbol']).to_s, description: (contract_item['description']).to_s, exch: (contract_item['exch']).to_s, option_type: (contract_item['option_type']).to_s, volume: (contract_item['volume']), bid: (contract_item['bid']), ask: (contract_item['ask']), underlying: (contract_item['underlying']).to_s, strike: (contract_item['strike']), change_percentage: (contract_item['change_percentage']), average_volume: (contract_item['average_volume']), last_volume: (contract_item['last_volume']), bidsize: (contract_item['bidsize']), asksize: (contract_item['asksize']), open_interest: (contract_item['open_interest']), expiration_date: (contract_item['expiration_date']).to_s, expiration_type: (contract_item['expiration_type']).to_s, root_symbol: (contract_item['root_symbol']).to_s ))
									end								
								end
							
						end
					end
				end
			#else
				#p "recent record exists"
			#end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Error for " + symbol + " exp date " + expirydate.to_s
			p e.backtrace
			p response
			#p "Rescued: #{e.inspect}"
			#p e.backtrace
		else

		ensure

		end
  end


  def clear_old_optionchains
		#p Optionchain.column_names
		#arr.keep_if { |h| Time.parse(h['day']) > timestamp }
		#where('created_at < ?', Date.today )
		p Optionchain.where('expiration_date < ?', Date.today ).delete_all

		#Logic
		#Assuming option chains are downloaded only 1 time/day
		#Check if option chains have been successfully downloaded today

		#p Optionchain.where('created_at < ?', Date.today ).delete_all
  end


  def get_stock_quotes_snapshot
	  	begin
			#paginate universe for 20 symbols at a time and execute API
			if 1==1
		  		(1..70).each do |p|  # needs to bbe made dynamic

		  			symbols_arr = Kaminari.paginate_array(Universe.pluck(:displaysymbol))
		  			symbols = symbols_arr.page(p).per(50)  #tested till 25.. can it be increased?
		  			symbols_string = symbols.join(",")
		  			#p symbols_string
		  			url_stock_quote_string = @baseurl_tradier + "quotes?symbols=" + symbols_string
					response = HTTParty.get(url_stock_quote_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})
					if response.code == 200 
						if response.parsed_response['quotes']['quote']
							symbols_quotes = response.parsed_response['quotes']['quote']
							symbols_quotes.each do |q|
								Stockprice.where(symbol: q['symbol']).delete_all
								stockprices = Stockprice.new(symbol: q['symbol'], last: q['last'])
								if stockprices.save
									p "saved to db " + q['symbol']
								else
									p "did not save to db " + q['symbol']
								end
							end
						else
							p "did not find quotes - quote for " + symbols_string.to_s
						end
					else
						p "API did not respond sucessfully for  " + symbols_string.to_s

					end
		  		end
		  	end

		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Error downloading stock prices .."
			p response
			#p "Rescued: #{e.inspect}"
			#p e.backtrace

		else

		ensure

		end
  end

  def get_targets(marketcap_type)
	  	begin 
		  	@queue = Limiter::RateQueue.new(5, interval: 60) #API throttling setup 5 calls / minute
		  	Stockprofile.select{|s| s['marketcap_type']==marketcap_type}.each do |sf|
		  		if sf['updated_at'] < 24.hours.ago
			  		target = Acquiretarget.new(sf['symbol']) # initialize Acquiretarget as target
			  		
			  		@queue.shift #API throttling block starts here
			  		if target.get_target
			  			Stockprofile.find_by(symbol: sf['symbol']).update_column(:target_price, target.get_target)
			  			p "target saved " + (sf['symbol']).to_s
			  		else
			  			p target.get_target_error + " " + (sf['symbol']).to_s
			  		end
			  	else
			  		p "record was updated less than 24 hours ago. " + (sf['symbol']).to_s
			  	end
		  	
		  	end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Error target prices .."
			p "Rescued: #{e.inspect}"
			p e.backtrace

		else

		ensure

		end
  end

  def get_earningscalendar
  	ed = Earningsdate.new(2021,1)
  	
  end




end
