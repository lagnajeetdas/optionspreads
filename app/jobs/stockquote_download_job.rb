class StockquoteDownloadJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later

    p "@@@@@@@@@@@@@@@@@@@@@ Starting download of stock universe @@@@@@@@@@@@@@@@@@@@"
    getstockuniverse
  
  end

  def getstockuniverse
  	# Finnhub API base parameters
  	finnhub_api_key = "sandbox_bv1u7mf48v6o5ed6gpdg"
  	finnhub_baseurl = "https://finnhub.io/api/v1/stock/symbol?"
  	finnhub_baseurl_2 = "https://finnhub.io/api/v1/stock/"
  	exchange = "US"
  	currency = "USD"
  	
  	# API call to get all symbols from finnhub
  	url_finnhub_stocksuniverse = finnhub_baseurl + "exchange=" + exchange + "&currency=" + currency + "&token=" + finnhub_api_key
  	response = HTTParty.get(url_finnhub_stocksuniverse)

  	#procesiing response
  	stocksuniverse_ary = Array[]
  	recommendation_ary_stock = Array[]

  	if response.code == 200
		stocksuniverse_ary = response.parsed_response

		# filter for MIC codes XNYS (NYSE) and XNGS (NASDAQ) stock exchanges
		stocksuniverse_ary = stocksuniverse_ary.select{ |item| item["mic"] == "XNYS" || item["mic"] == "XNGS" }

		#filter for security type - common stocks, exchange traded products, american depository receipts 
		stocksuniverse_ary = stocksuniverse_ary.select{ |item| item["type"] == "Common Stock" || item["type"] == "ADR" || item["type"] == "ETP" || item["type"] == "ETN" || item["type"] == "REIT" }
    end

    # API call to get all symbols from finnhub
    #https://finnhub.io/api/v1/stock/recommendation?symbol=AAPL&token=bv1u7mf48v6o5ed6gpd0
  	recommendation_ary = Array[]
  	stocksuniverse_ary.take(10).each do |security|
	  	url_finnhub_recommendation = finnhub_baseurl_2 + "recommendation?symbol=" + security['displaySymbol'] + "&token=" + finnhub_api_key
	  	response = HTTParty.get(url_finnhub_recommendation)
	  	
	  	
	  	if response.code == 200
	  		recommendation_ary_stock = response.parsed_response
	  		if !recommendation_ary_stock.empty?
	  			recommendation_ary =  recommendation_ary.push(recommendation_ary_stock[0])
	  		end
	  	end
	end

	p recommendation_ary

    p "@@@@@@@@@@@@@@@@@@@@@ Finished download of stock universe @@@@@@@@@@@@@@@@@@@@"


  end

end
