class OptionsStragizerJob < ApplicationJob
   
	
  def perform(service_name)
    # Do something later
    @tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
    @baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"

    #get_option_expirydates(ticker: symbol)
	universes = Universe.pluck(:displaysymbol)
	

	@option_spreads_scenarios = Array[]

	case service_name
	  	when "calc_op_spreads"
			universes.each do |security|
				#p security
				calc_op_spreads(security: security)
			end
	  	when "calc_high_open_interests"
	  		top_high_open_interest
	  	else
	  		p "no job found"
	 end



	


  end

  def get_option_expirydates(ticker:)
	    begin 
	      url_options_expiry_string = @baseurl_tradier + "options/expirations?symbol=" + ticker + "&includeAllRoots=false&strikes=false"
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
		  	url_options_chain_string = @baseurl_tradier + "options/chains?symbol=" + symbol + "&expiration=" + expirydate + "&greeks=false"
			response = HTTParty.get(url_options_chain_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})
			

			if response.code == 200 #valid response
				if response.parsed_response['options']['option']
					@optionchain_data = response.parsed_response['options']['option']
					if !@optionchain_data.empty?
						#p @optionchain_data

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

  def calc_op_spreads(security:)
  	
  	p "@@@@@@@@@@@@@@@@@@@@ Starting option scenario calcs@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  	
  	begin 
	  	stock_latest_price = -1 
	  	if ((Stockprice.where(symbol: security)).last)
			p stock_latest_price = ((Stockprice.where(symbol: security)).last)['last']
		end
		
		if stock_latest_price != -1 && !stock_latest_price.nil?
			expiry_dates_unique_array = Array[]

			## Call or put is addressed here..
			optionchains = Optionchain.where(underlying: security).where(option_type: 'call')
			
			expiry_dates_unique_array =  optionchains.distinct.pluck(:expiration_date)

			expiry_dates_unique_array.each do |e_date|
				#p e_date
			
				option_strikes_array = Array[]
				optionchains = optionchains.uniq{ |s| s['symbol'] } #get unique option chains by option symbol
				 optionchains

				#Loop through all contracts in option chain of an expiry date 
				optionchains.each do |contract_item|
					if contract_item['expiration_date'] == e_date  && contract_item['root_symbol'] == security								
						
						#create an array of option strikes
						option_strikes_array.push((contract_item['strike'])) 
					end
				end

				option_strikes_array = option_strikes_array.uniq
				
				#p option_strikes_array
				#Check if option strikes array is not empty 
				if 1==1 && !option_strikes_array.empty?
					#find strike price closest to stock quote to set anchor
					h = option_strikes_array.map(&:to_f).sort.group_by{|e| e <=> stock_latest_price.to_f}
					#p h
					if 1==1
						anchor_strike = (h[-1].last || h[1].first)
						strike_gap = h[-1].last - h[-1][-2]
						
						#Create a strike_gap set array
						strike_gap_set = Array[]
						anchor_set = Array[]
						strike_gap_set.push(strike_gap)
						strike_gap_set.push(strike_gap * 2)
						strike_gap_set.push(strike_gap * 3)

						strike_gap_set.each do |sg|
							#Create an anchor set array
							anchor_set =  (anchor_strike..anchor_strike*1.3).step(sg).to_a 
							
							threshold = [7, anchor_set.length()].min

							#Loop through each anchor price in anchor_set
							anchor_set.take(threshold).each do |anc_price|
								buy_contract_ask_price = -1
								sell_contract_bid_price = -1
								

								risk = -1
								reward = -1 
								rr_ratio = -1 
								perc_change = -1

								buy_call_strike = anc_price 
								sell_call_strike = anc_price + sg

								
								
								#Get ask price of buy option contract with strike price = buy_call_strike 
								t_contract_buy = optionchains.detect {|contract_item| contract_item['strike'].to_s == buy_call_strike.to_s }

								unless t_contract_buy.nil?
										buy_contract_ask_price =  t_contract_buy['ask']
										buy_contract_symbol = t_contract_buy['symbol']
										buy_contract_iv = t_contract_buy['mid_iv']
								end

								#Get bid price of sell option contract with strike price = sell_call_strike -->
								t_contract_sell = optionchains.detect {|contract_item| contract_item['strike'].to_s == sell_call_strike.to_s  }

								unless t_contract_sell.nil?
										sell_contract_bid_price =  t_contract_sell['bid']
										sell_contract_symbol = t_contract_sell['symbol']
										sell_contract_iv = t_contract_sell['mid_iv']
								end


								#if both bid and ask of the 2 contracts are valid, calc risk and reward
								if buy_contract_ask_price != -1 && sell_contract_bid_price != -1 
									risk = 100 * (buy_contract_ask_price.to_f - sell_contract_bid_price.to_f)
									reward = (100.0 * sg.to_f) - risk.to_f
									
									if risk != 0
										rr_ratio = reward.to_f / risk.to_f
									end

									perc_change = 100*((sell_call_strike.to_f - stock_latest_price)/stock_latest_price)
								
									Optionscenario.where(expiry_date: e_date).where(buy_contract_symbol: buy_contract_symbol).where(sell_contract_symbol: sell_contract_symbol).delete_all
									
									#@option_spreads_scenarios.push({ "underlying" => security, "expiry_date" => e_date, "buy_strike" => buy_call_strike, "sell_strike" => sell_call_strike, "risk" => risk, "reward" => reward, "rr_ratio" => rr_ratio, "perc_change" => perc_change, "buy_contract_symbol" => buy_contract_symbol , "sell_contract_symbol" => sell_contract_symbol, "buy_contract_iv" => buy_contract_iv , "sell_contract_iv" => sell_contract_iv    })
									

									@optionscenario = Optionscenario.new(underlying: security, expiry_date: e_date, buy_strike: buy_call_strike, sell_strike: sell_call_strike, risk: risk, reward: reward, rr_ratio: rr_ratio, perc_change: perc_change, buy_contract_symbol: buy_contract_symbol, sell_contract_symbol: sell_contract_symbol, buy_contract_iv: buy_contract_iv , sell_contract_iv: sell_contract_iv )
									if @optionscenario.save
										#p "saved to option scenario db"
									else
										p "could not save to option scenario db  - " + security.to_s + " -  " + e_date.to_s + " - " +  buy_contract_symbol.to_s + " - " +  sell_contract_symbol.to_s
									end

								end
							end
						end
					end
				else
					p "option strike array is empty for " + security.to_s
				end
			end

		end

	rescue StandardError, NameError, NoMethodError, RuntimeError => e
		p "Error calculating spreads " + security.to_s
		p "Rescued: #{e.inspect}"
		p e.backtrace
		#p response

	else

	ensure

	end
	p "@@@@@@@@@@@@@@@@@@@@ Finished option scenario calcs@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

  end




  def top_high_open_interest

  	p "@@@@@@@@@@@@@@@@@@@@ Starting high open interest options calc @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

  	stock_latest_price = -1
  	stock_description = ""
  	begin
  		p Optionhighopeninterest.delete_all
	  	@high_open_interest = Optionchain.select{ |o| o['open_interest']>1 }.group_by { |r| r["open_interest"] }.sort_by  { |k, v| -k }.first(500).map(&:last).flatten
	  	@high_open_interest.each do |hoi|
	  		if ((Stockprice.where(symbol: hoi.underlying)).last)
				stock_latest_price = ((Stockprice.where(symbol: hoi.underlying)).last)['last']
			end
			
			if ((Universe.where(displaysymbol: hoi.underlying)).last)
				stock_description = ((Universe.where(displaysymbol: hoi.underlying)).last)['description']
			end
	  		

			@optionhighopeninterest =  Optionhighopeninterest.new(underlying: hoi.underlying, expiration_date: hoi.expiration_date, strike: hoi.strike, bid: hoi.bid, ask: hoi.ask, last_volume: hoi.last_volume, open_interest: hoi.open_interest, symbol: hoi.symbol, quote: stock_latest_price, description: stock_description, option_type: hoi.option_type )
			if @optionhighopeninterest.save
				
			else
				p "could not save high open interest to db"
			end

	  		
	  	end
	rescue StandardError, NameError, NoMethodError, RuntimeError => e
		p "Rescued: #{e.inspect}"
		
	else

	ensure

	end

	p "@@@@@@@@@@@@@@@@@@@@ Finished high open interest options calc @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
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
