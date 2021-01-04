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
		  		
		  		page_size = 50
		  		num_pages_universe = ((Universe.count)/page_size)+1

		  		(1..num_pages_universe).each do |pg|  

		  			symbols_arr = Kaminari.paginate_array(universes)
		  			symbols = symbols_arr.page(pg).per(page_size)  

		  			if 1==1
		  				p "Start page " pg.to_s
				  		p "@@@@@@@@@@@@@@@@@@@@ Starting option scenario calcs@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
						symbols.each do |security|
							#p security
							calc_op_spreads(security: security)					
						end
						p "@@@@@@@@@@@@@@@@@@@@ Finished option scenario calcs@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
						p "End page " pg.to_s
						OptionsStragizerJob.perform_later("calc_top_option_spreads")
					end
				end
		  	when "calc_high_open_interests"
		  		top_high_open_interest
		  	when "calc_top_option_spreads"
		  		top_option_spreads
		  	when "delete_old_option_spreads"
		  		delete_old_option_spreads
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
	  	begin 
		  	stock_latest_price = -1 
		  	if ((Stockprice.where(symbol: security)).last)
				stock_latest_price = ((Stockprice.where(symbol: security)).last)['last']
			end
			
			if stock_latest_price != -1 && !stock_latest_price.nil?
				expiry_dates_unique_array = Array[]

				## Call or put is addressed here..
				#optionchains = Optionchain.where(underlying: security).where(option_type: 'call')
				Optionscenario.where(underlying: security).delete_all
											
				expiry_dates_unique_array =  Optionchain.where(underlying: security).distinct.pluck(:expiration_date)

				optionscenario_import = Array[] 
				if !expiry_dates_unique_array.empty?
					expiry_dates_unique_array.each do |e_date|
							optionchains = Optionchain.where(underlying: security).where(option_type: 'call').where(expiration_date: e_date)
							#p e_date

							if !optionchains.empty?
								option_strikes_array = Array[]
								optionchains = optionchains.uniq{ |s| s['symbol'] } #get unique option chains by option symbol
								#p optionchains

								

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
									if 1==1 && !h.empty?
										anchor_strike = (h[-1].last || h[1].first)
										strike_gap = h[-1].last - h[-1][-2]
										
										#Create a strike_gap set array
										strike_gap_set = Array[]
										anchor_set = Array[]
										strike_gap_set.push(strike_gap)
										strike_gap_set.push(strike_gap * 2)
										strike_gap_set.push(strike_gap * 3)
										strike_gap_set
										
										strike_gap_set.each do |sg|
											#Create an anchor set array
											anchor_set =  (anchor_strike..anchor_strike*1.3).step(sg).to_a 
											
											threshold = [5, anchor_set.length()].min

											#Loop through each anchor price in anchor_set
											anchor_set
											anchor_set.take(threshold).each do |anc_price|
												buy_contract_ask_price = -1
												sell_contract_bid_price = -1
												

												risk = -1
												reward = -1 
												rr_ratio = -1 
												perc_change = -1

												#p "buy strike"
												buy_call_strike = anc_price 
												#p "sell strike"
												sell_call_strike = anc_price + sg

												
												
												#Get ask price of buy option contract with strike price = buy_call_strike 
												t_contract_buy = optionchains.detect {|contract_item| contract_item['strike'] == buy_call_strike && contract_item['expiration_date']==e_date  }

												unless t_contract_buy.nil?
														#p "buy contract ask"
														buy_contract_ask_price =  t_contract_buy['ask']
														buy_contract_symbol = t_contract_buy['symbol']
														buy_contract_iv = t_contract_buy['mid_iv']
												end

												#Get bid price of sell option contract with strike price = sell_call_strike -->
												t_contract_sell = optionchains.detect {|contract_item| contract_item['strike'] == sell_call_strike && contract_item['expiration_date']==e_date   }

												unless t_contract_sell.nil?
														#p "sell contract bid"
														sell_contract_bid_price =  t_contract_sell['bid']
														sell_contract_symbol = t_contract_sell['symbol']
														sell_contract_iv = t_contract_sell['mid_iv']
												end


												#if both bid and ask of the 2 contracts are valid, calc risk and reward
												if buy_contract_ask_price != -1 && sell_contract_bid_price != -1 
													#p "risk"
													risk = 100 * (buy_contract_ask_price.to_f - sell_contract_bid_price.to_f)
													
													#p "reward"
													reward = (100.0 * sg.to_f) - risk.to_f
													
													if risk != 0
														rr_ratio = reward.to_f / risk.to_f
													end

													perc_change = 100*((sell_call_strike.to_f - stock_latest_price)/stock_latest_price)
												
													
													#@option_spreads_scenarios.push({ "underlying" => security, "expiry_date" => e_date, "buy_strike" => buy_call_strike, "sell_strike" => sell_call_strike, "risk" => risk, "reward" => reward, "rr_ratio" => rr_ratio, "perc_change" => perc_change, "buy_contract_symbol" => buy_contract_symbol , "sell_contract_symbol" => sell_contract_symbol, "buy_contract_iv" => buy_contract_iv , "sell_contract_iv" => sell_contract_iv    })
													
													optionscenario_import.push(Optionscenario.new(underlying: security, expiry_date: e_date, buy_strike: buy_call_strike, sell_strike: sell_call_strike, risk: risk, reward: reward, rr_ratio: rr_ratio, perc_change: perc_change, buy_contract_symbol: buy_contract_symbol, sell_contract_symbol: sell_contract_symbol, buy_contract_iv: buy_contract_iv , sell_contract_iv: sell_contract_iv ))
													#@optionscenario = Optionscenario.new(underlying: security, expiry_date: e_date, buy_strike: buy_call_strike, sell_strike: sell_call_strike, risk: risk, reward: reward, rr_ratio: rr_ratio, perc_change: perc_change, buy_contract_symbol: buy_contract_symbol, sell_contract_symbol: sell_contract_symbol, buy_contract_iv: buy_contract_iv , sell_contract_iv: sell_contract_iv )
													#if @optionscenario.save
													#	#p "saved to option scenario db"
													#else
													#	p "could not save to option scenario db  - " + security.to_s + " -  " + e_date.to_s + " - " +  buy_contract_symbol.to_s + " - " +  sell_contract_symbol.to_s
													#end

												end
											end
										end
									end
								else
									p "option strike array is empty for " + security.to_s
								end
							else
								p "Option chain not found for " + security.to_s
							end
					end

					if !optionscenario_import.empty?
						Optionscenario.import optionscenario_import
						optionscenario_import = Array[] 
						#p "saved import to db"
					else
						p "could not save to db optionscenario_import" + security.to_s
					end
				else
					p "expiry dates array is empty " + symbol.to_s
				end

			else
				p "did not find latest stock price " + security.to_s
			end

		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Error calculating spreads " + security.to_s
			p "Rescued: #{e.inspect}"
			#p e.backtrace
			#p response
			if !optionscenario_import.empty?
				Optionscenario.import optionscenario_import
				optionscenario_import = Array[] 
				p "Error but saved import to db"
			else
				p "Exception: could not save to db optionscenario_import " + security.to_s
			end


		else

		ensure
			
		end
  end

  def top_high_open_interest

	  	p "@@@@@@@@@@@@@@@@@@@@ Starting high open interest options calc @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

	  	stock_latest_price = -1
	  	stock_description = ""
	  	begin
	  		p Optionhighopeninterest.delete_all
	  		@high_open_interest = Optionchain.order('open_interest DESC').limit(100)
	  		p Optionchain.count
		  	p @high_open_interest.count
		  	#@high_open_interest = Optionchain.select{ |o| o['open_interest']>1 }.group_by { |r| r["open_interest"] }.sort_by  { |k, v| -k }.first(500).map(&:last).flatten
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

  def top_option_spreads

  	 
	  	p "@@@@@@@@@@@@@@@@@@@@ Starting updating top option spreads @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

	  	stock_latest_price = -1
	  	stock_description = ""
	  	stock_industry = ""

	  	begin
	  		p Topoptionscenario.delete_all

	  		@best_rr_options = Optionscenario.order('rr_ratio DESC').limit(500)


		  	#@best_rr_options = Optionscenario.all.group_by { |r| r["rr_ratio"] }.sort_by  { |k, v| -k }.first(5).map(&:last).flatten
		  	p Optionscenario.count
		  	p @best_rr_options.count
		  	if 1==1
			  	@best_rr_options.each do |hoi|
			  		if ((Stockprice.where(symbol: hoi.underlying)).last)
						stock_latest_price = ((Stockprice.where(symbol: hoi.underlying)).last)['last']
					end
					
					if ((Universe.where(displaysymbol: hoi.underlying)).last)
						stock_description = ((Universe.where(displaysymbol: hoi.underlying)).last)['description']
					end

					if ((Stockprofile.where(symbol: hoi.underlying)).last)
						stock_industry = ((Stockprofile.where(symbol: hoi.underlying)).last)['industry']
					end
			  		

					@topoptionscenario =  Topoptionscenario.new(underlying: hoi.underlying, expiry_date: hoi.expiry_date, buy_strike: hoi.buy_strike, sell_strike: hoi.sell_strike, risk: hoi.risk, reward: hoi.reward, rr_ratio: hoi.rr_ratio, perc_change: hoi.perc_change, buy_contract_symbol: hoi.buy_contract_symbol, sell_contract_symbol: hoi.sell_contract_symbol, stock_quote: stock_latest_price, stock_description: stock_description, buy_contract_iv: hoi.buy_contract_iv, sell_contract_iv: hoi.sell_contract_iv, industry: stock_industry )
					if @topoptionscenario.save
						
					else
						p "could not save top option scenario to db"
					end

			  		
			  	end
			end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Rescued: #{e.inspect}"
			
		else

		ensure

		end

		p "@@@@@@@@@@@@@@@@@@@@ Finished updating top option spreads @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  end

  def delete_old_option_spreads
  	Optionscenario.where('created_at <= ?', Date.today ).delete_all
  end

  
end
