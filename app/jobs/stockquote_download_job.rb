class StockquoteDownloadJob < ApplicationJob
  queue_as :default
  extend Limiter::Mixin
  
  def perform(service_name)
    # Do something later
    # Finnhub API base parameters
    p "@@@@@@@@@@@@@@@@@@@@@ Background Job Initialized  @@@@@@@@@@@@@@@@@@@@"

    @finnhub_api_key = "sandbox_bv1u7mf48v6o5ed6gpdg"
    @finnhub_api_key_prod = "bv1u7mf48v6o5ed6gpd0"
  	@finnhub_baseurl = "https://finnhub.io/api/v1/stock/symbol?"
  	@finnhub_baseurl_2 = "https://finnhub.io/api/v1/stock/"
  	@exchange = "US"
  	@currency = "USD"

  	#get models into instances
  	@universes = Universe.all
  	@recommendations = Recommendation.all
  	@stockprofiles = Stockprofile.all

    #function calls
    #getstockuniverse
  	#getrecommendations
  	case service_name
	  	when "universe"
	  		getstockuniverse
	  	when "recommendation"
	  		getrecommendations
	  	when "metadata"
	  		getstockprofiledata
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
			    	@recommendation = Recommendation.new(buy: recommendation_ary_stock[0]['buy'], hold: recommendation_ary_stock[0]['hold'], period: recommendation_ary_stock[0]['period'], sell: recommendation_ary_stock[0]['sell'], strongbuy: recommendation_ary_stock[0]['strongBuy'], strongsell: recommendation_ary_stock[0]['strongSell'], symbol: recommendation_ary_stock[0]['symbol'] )
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
  	@queue = Limiter::RateQueue.new(60, interval: 60)

  	@universes.each do |security|
  		@queue.shift
  		getstockprofiledata_apicall(security: security) 
	end
	

	p "@@@@@@@@@@@@@@@@@@@@@ Stocks meta data download finished. @@@@@@@@@@@@@@@@@@@@"  


  end

  def getstockprofiledata_apicall(security:)
  	stockprofile_ary = Array[]
  	_marketcaptype = ""
  	url_finnhub_stockprofile = @finnhub_baseurl_2 + "profile2?symbol=" + security['displaysymbol'] + "&token=" + @finnhub_api_key_prod
	  	response = HTTParty.get(url_finnhub_stockprofile)
	  	if response.code == 200
	  		stockprofile_ary = response.parsed_response
	  		if !stockprofile_ary.empty?
	  			
	  			
	  			if @stockprofiles.select{ |s| s['symbol']==security['displaysymbol'] }.empty?
	  				p security['displaysymbol'] 
	  				p (stockprofile_ary['marketCapitalization'])
	  				if (stockprofile_ary['marketCapitalization']) && (stockprofile_ary['marketCapitalization'])!=""
		  				if (stockprofile_ary['marketCapitalization']).to_f < 3000.0
		  					_marketcaptype = "Small Cap"
		  				elsif (stockprofile_ary['marketCapitalization']).to_f > 10000.0
		  					_marketcaptype = "Large Cap"
		  				else
							_marketcaptype = "Mid Cap"
		  				end
		  			end
		  			p _marketcaptype

			    	@stockprofile = Stockprofile.new(symbol: stockprofile_ary['ticker'], industry: stockprofile_ary['finnhubIndustry'], marketcap: stockprofile_ary['marketCapitalization'], logo: stockprofile_ary['logo'], marketcap_type: _marketcaptype )
			    	if @stockprofile.save
				      p "Saved stock meta data to db " + security['displaysymbol'].to_s
				    else
				      p "Did not save stock meta data to db " + security['displaysymbol'].to_s
				    end
				end
	  		end
	  	end

  end

end
