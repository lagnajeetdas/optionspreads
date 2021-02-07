class Calculatespreads
	
	def initialize(optionchain, quote, symbol, e_dates, strategy, target, jump, maxrisk, minreward, minrr)
		@quote = quote.to_f
		@symbol = symbol
		@optionchain = optionchain
		@e_dates = e_dates
		@optionscenario_import = Array[] 
		@strategy = strategy
		@anchor_range = (jump.to_f)/100
		@target = target.to_f
		@maxrisk = maxrisk.to_f
		@minreward = minreward.to_f
		@minrr = minrr.to_f
		@max_number_anchors = 10

		case @strategy
		  	when "call-debit"
				compute_spreads("call", "debit", "call-debit")
		  	when "call-credit"
		  		compute_spreads("call", "credit", "call-credit")
		  	when "put-debit"
		  		compute_spreads("put", "debit", "put-debit")
		  	when "put-credit"
		  		compute_spreads("put", "credit", "put-credit")
		  	when "long-straddle"
		  		compute_spreads("buy-call-put-same", "debit", "long-straddle", @target)
		  	when "short-straddle"
		  		compute_spreads("sell-call-put-same", "credit", "short-straddle")
		end

		p "Array Length"
		p @optionscenario_import.length()
	end

	def compute_spreads(op_type, entry_type, strategy="default", target = -1)

		begin 
		  	stock_latest_price = @quote
			if stock_latest_price != -1 && !stock_latest_price.nil?
				expiry_dates_unique_array = Array[]
				expiry_dates_unique_array =  @e_dates
				if !expiry_dates_unique_array.empty?
					expiry_dates_unique_array.each do |e_date|
							#optionchains = @optionchain.where(underlying: @symbol).where(option_type: 'call').where(expiration_date: e_date)
							if strategy=="long-straddle" or strategy=="short-straddle"
								optionchains  =  @optionchain.select{ |oc| oc[:underlying]==@symbol.to_s && oc[:expiration_date]==e_date.to_s }
							else
								optionchains  =  @optionchain.select{ |oc| oc[:underlying]==@symbol.to_s && oc[:option_type]==op_type.to_s && oc[:expiration_date]==e_date.to_s }
							end

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
									if 1==1 && !h.empty? && !h[-1].nil?
										anchor_strike = (h[-1].last || h[1].first)
										strike_gap = h[-1].last - h[-1][-2]
										
										#Create a strike_gap set array
										strike_gap_set = Array[]
										anchor_set = Array[]
										strike_gap_set.push(strike_gap)
										strike_gap_set.push(strike_gap * 2)
										strike_gap_set.push(strike_gap * 3)
										strike_gap_set.push(strike_gap * 4)
										strike_gap_set
										
										strike_gap_set.each do |sg|
											#Create an anchor set array
											spread_type = op_type + "-" + entry_type
											if strategy == "call-debit" or strategy == "put-credit" 
												anchor_set =  (anchor_strike..anchor_strike* (1+ @anchor_range) ).step(sg).to_a 
											elsif strategy == "call-credit" or strategy == "put-debit" 
												anchor_set = (anchor_strike.to_i).downto(anchor_strike* (1- @anchor_range)).select.with_index { |x, idx| idx % sg.ceil == 0 }.each { |x|  } 
											elsif strategy =="long-straddle" or strategy =="short-straddle"
												anchor_set_up =  (anchor_strike.to_i..anchor_strike* (1+ @anchor_range) ).step(sg).to_a 
												anchor_set_down = (anchor_strike.to_i).downto(anchor_strike* (1- @anchor_range)).select.with_index { |x, idx| idx % sg.ceil == 0 }.each { |x|  } 
												anchor_set = ((anchor_set_up + anchor_set_down).map(&:to_f).uniq).sort
												#anchor_set = anchor_set.map(&:to_f).uniq
											end

											threshold = [@max_number_anchors, anchor_set.length()].min

											#Loop through each anchor price in anchor_set
											anchor_set
											anchor_set.take(threshold).each do |anc_price|
												
												buy_contract_ask_price_call = -1
												sell_contract_bid_price_call = -1
												buy_contract_ask_price_put = -1
												sell_contract_bid_price_put = -1
												t_contract_buy_call = nil
												t_contract_buy_put = nil
												t_contract_sell_call = nil
												t_contract_sell_put = nil
												

												risk = -1
												reward = -1 
												rr_ratio = -1 
												perc_change = -1
												entry_cost = -1


												buy_call_strike = anc_price
												buy_put_strike = anc_price 

												if strategy == "call-debit" or strategy == "put-credit"
													sell_call_strike = anc_price + sg
												elsif strategy == "call-credit" or strategy == "put-debit"
													sell_call_strike = anc_price - sg
												elsif strategy =="long-straddle" or strategy == "short-straddle"
													sell_call_strike = -1
													sell_put_strike = -1
												end
												

												##BUY
												#Get ask price of buy option contract with strike price = buy_call_strike 
												if strategy == "call-debit" or strategy == "put-credit" or strategy == "call-credit" or strategy == "put-debit"
													t_contract_buy_call = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == buy_call_strike && contract_item[:expiration_date]==e_date.to_s  }
												elsif strategy =="long-straddle"
													t_contract_buy_call = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == buy_call_strike && contract_item[:expiration_date]==e_date.to_s && contract_item[:option_type]=='call'  }
													t_contract_buy_put = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == buy_put_strike && contract_item[:expiration_date]==e_date.to_s && contract_item[:option_type]=='put'  }
												end


												unless t_contract_buy_call.nil?
														#p "buy contract ask"
														buy_contract_ask_price_call =  t_contract_buy_call[:ask]
														buy_contract_symbol_call = t_contract_buy_call[:symbol]
														buy_contract_iv_call = t_contract_buy_call[:ask_iv]
												end
												
												unless t_contract_buy_put.nil?
														#p "buy contract ask"
														buy_contract_ask_price_put =  t_contract_buy_put[:ask]
														buy_contract_symbol_put = t_contract_buy_put[:symbol]
														buy_contract_iv_put = t_contract_buy_put[:ask_iv]
												end

												
												##SELL 
												if strategy == "call-debit" or strategy == "put-credit" or strategy == "call-credit" or strategy == "put-debit"
													t_contract_sell_call = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == sell_call_strike && contract_item[:expiration_date]==e_date.to_s   }										
												elsif strategy =="short-straddle"
													t_contract_sell_call = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == sell_call_strike && contract_item[:expiration_date]==e_date.to_s && contract_item[:option_type]=='call'  }
													t_contract_sell_put = optionchains.detect {|contract_item| (contract_item[:strike]).to_f == sell_put_strike && contract_item[:expiration_date]==e_date.to_s && contract_item[:option_type]=='put'  }
												end


												unless t_contract_sell_call.nil?
														#p "sell contract bid"
														sell_contract_bid_price_call =  t_contract_sell_call[:bid]
														sell_contract_symbol_call = t_contract_sell_call[:symbol]
														sell_contract_iv_call = t_contract_sell_call[:bid_iv]
												end


												unless t_contract_sell_put.nil?
														#p "sell contract bid"
														sell_contract_bid_price_put =  t_contract_sell_put[:bid]
														sell_contract_symbol_put = t_contract_sell_put[:symbol]
														sell_contract_iv_put = t_contract_sell_put[:bid_iv]
												end


												#if both bid and ask of the 2 contracts are valid, calc risk and reward
												if strategy == "call-debit" or strategy == "put-credit" or strategy == "call-credit" or strategy == "put-debit"
													entry_cost = 100 * (buy_contract_ask_price_call.to_f - sell_contract_bid_price_call.to_f)
												elsif strategy == "long-straddle"
													entry_cost = 100 * (buy_contract_ask_price_call.to_f + buy_contract_ask_price_put.to_f)
												elsif strategy == "short-straddle"
													entry_cost = 100 * (sell_contract_bid_price_call.to_f + sell_contract_bid_price_put.to_f)
												end


												if entry_type=="debit"
													risk = entry_cost.to_f
													if strategy == "call-debit" or strategy== "put-debit"
														reward = (100.0 * sg.to_f) - risk.to_f
													elsif strategy == "long-straddle"
														target
														if target != -1 && !target.nil?
															reward = (100*((target - buy_call_strike).to_i).abs).to_f - risk.to_f
														else
															reward = Float::INFINITY
														end

													end
														
												else
													risk = (100.0 * sg.to_f) + entry_cost.to_f
													reward = -1 * entry_cost.to_f
												end

												
												if risk != 0
													rr_ratio = reward.to_f / risk.to_f
												end

												

												if strategy == "call-debit" or strategy == "put-credit" or strategy == "call-credit" or strategy == "put-debit"
													perc_change = 100*((sell_call_strike.to_f - stock_latest_price)/stock_latest_price)
													if perc_change.abs<(@anchor_range*100) and reward>@minreward and risk<@maxrisk and rr_ratio>@minrr
														@optionscenario_import.push({underlying: @symbol, expiry_date: e_date, buy_strike: buy_call_strike, sell_strike: sell_call_strike, risk: risk.round(1), reward: reward.round(1), rr_ratio: rr_ratio.round(1), perc_change: perc_change.round(1), buy_contract_symbol: buy_contract_symbol_call, sell_contract_symbol: sell_contract_symbol_call, buy_contract_iv: buy_contract_iv_call , sell_contract_iv: sell_contract_iv_call, quote: stock_latest_price, entry_cost: entry_cost.round(1) })
													end
												elsif strategy== "long-straddle"
													if target != -1 && !target.nil?
														perc_change = 100*((target.to_f - stock_latest_price)/stock_latest_price)
													else
														perc_change = Float::INFINITY
													end
												if risk<@maxrisk	
													@optionscenario_import.push({underlying: @symbol, expiry_date: e_date, buy_strike: buy_call_strike, sell_strike: buy_put_strike, risk: risk.round(1), reward: reward.round(1), rr_ratio: rr_ratio.round(1), perc_change: perc_change.round(1), buy_contract_symbol: buy_contract_symbol_call, sell_contract_symbol: buy_contract_symbol_put, buy_contract_iv: buy_contract_iv_call , sell_contract_iv: buy_contract_iv_put, quote: stock_latest_price, entry_cost: entry_cost.round(1) })
												end	
													 
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