class Calculatespreads
	
	def initialize(optionchain, quote, symbol, e_dates)
		@quote = quote.to_f
		@symbol = symbol
		@optionchain = optionchain
		@e_dates = e_dates
		@optionscenario_import = Array[] 
		call_debit_spreads

		p "Array Length"
		p @optionscenario_import.length()
	end

	def call_debit_spreads

		begin 
		  	stock_latest_price = @quote
			if stock_latest_price != -1 && !stock_latest_price.nil?
				expiry_dates_unique_array = Array[]
				
				expiry_dates_unique_array =  @e_dates


				if !expiry_dates_unique_array.empty?
					expiry_dates_unique_array.each do |e_date|
							#optionchains = @optionchain.where(underlying: @symbol).where(option_type: 'call').where(expiration_date: e_date)
							optionchains  =  @optionchain.select{ |oc| oc[:underlying]==@symbol.to_s && oc[:option_type]=='call' && oc[:expiration_date]==e_date.to_s }

							if !optionchains.empty?
								option_strikes_array = Array[]
								#optionchains = optionchains.uniq{ |s| s[:symbol] } #get unique option chains by option symbol

								#Loop through all contracts in option chain of an expiry date 
								optionchains.each do |contract_item|
									if contract_item[:expiration_date] == e_date  && contract_item[:root_symbol] == @symbol								
										
										#create an array of option strikes
										option_strikes_array.push((contract_item[:strike])) 
									end
								end

								option_strikes_array = option_strikes_array.uniq
								
								#p option_strikes_array
								#Check if option strikes array is not empty 
								if 1==1 && !option_strikes_array.empty?
									#find strike price closest to stock quote to set anchor
									h = option_strikes_array.map(&:to_f).sort.group_by{|e| e <=> stock_latest_price.to_f}
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
											#p anchor_set
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

												t_contract_buy = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == buy_call_strike && contract_item[:expiration_date]==e_date.to_s  }

												unless t_contract_buy.nil?
														#p "buy contract ask"
														buy_contract_ask_price =  t_contract_buy[:ask]
														buy_contract_symbol = t_contract_buy[:symbol]
														buy_contract_iv = t_contract_buy[:ask_iv]
												end

												#Get bid price of sell option contract with strike price = sell_call_strike -->
												t_contract_sell = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == sell_call_strike && contract_item[:expiration_date]==e_date.to_s   }

												unless t_contract_sell.nil?
														#p "sell contract bid"
														sell_contract_bid_price =  t_contract_sell[:bid]
														sell_contract_symbol = t_contract_sell[:symbol]
														sell_contract_iv = t_contract_sell[:bid_iv]
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
												
													@optionscenario_import.push({underlying: @symbol, expiry_date: e_date, buy_strike: buy_call_strike, sell_strike: sell_call_strike, risk: risk.round(1), reward: reward.round(1), rr_ratio: rr_ratio.round(1), perc_change: perc_change.round(1), buy_contract_symbol: buy_contract_symbol, sell_contract_symbol: sell_contract_symbol, buy_contract_iv: buy_contract_iv , sell_contract_iv: sell_contract_iv, quote: stock_latest_price, entry_cost: risk.round(1) })
												end
											end
										end
									end
								else
									p "option strike array is empty for " + @symbol.to_s
								end
							else
								p "Option chain not found for " + @symbol.to_s
							end
					end
				
				else
					p "expiry dates array is empty " 
				end
			else
				p "did not find latest stock price " 
			end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Error calculating spreads " 
			p "Rescued: #{e.inspect}"
			p e.backtrace
		else
		ensure
		end
	end

	def analysis_results
		@optionscenario_import
	end


end