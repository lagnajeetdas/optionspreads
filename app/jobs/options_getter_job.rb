class OptionsGetterJob < ApplicationJob
	require 'optionexpirydates'
  	require 'optionchains'
  	require 'livequotetradier'
  	require 'date'
  	require 'updateoptionlog'
  	require 'calculatespreads'

	def perform(service)
		case service
			when "get"
				get_main_loop
			when "calculate_spreads"
				calculate_spreads_main_loop
			when "calculate_put_sells"
				calculate_put_sells
		end
	end

	def get_main_loop
		#Variables
		c = 0
		max_num_e_dates = 4

		#Log the start time of download
		update_optiondowload_log("option_chain_download","Started", c)

		#Extract all symbols in Universe, fast	
		universes = Universe.pluck(:displaysymbol)
		universe_ids = Universe.pluck(:id)

		#Download ALL live stock quotes into local DB
		lq_universe = Livequotetradier.new(universes,1)


		#loop through each underlying in universe 
		universes.each do |u|
			p c.to_s + ". " + u.to_s

			begin
				#declare default values of temp variables
				quote = -1
				e_dates = Array[]
				optionchain_import = Array[]

				##Get Live Stock Quote from local DB or direct API call
				if ((Stockprice.where(symbol: u)).last)
					_quote = ((Stockprice.where(symbol: u)).last)['last']
				else
					lq = Livequotetradier.new(u)
					_quote = lq.latest_price
					p "Queried latest price using API"
				end
				##################			

				##Get Expiry Dates
				oed = Optionexpirydates.new(u)
				e_dates = oed.e_dates
				e_dates = e_dates.take([max_num_e_dates,e_dates.length()].min)
				##################

				##Get option chains
				if !e_dates.empty? and !e_dates.nil?
					oc = Optionchains.new(u,e_dates)
					optionchains_data = oc.chains
					p (optionchains_data.length()).to_s + " chains"
				end
				###################

				##Store Option Chains
				if !optionchains_data.empty? 
					optionchains_data.each do |contract_item|
						contract_item_greeks = contract_item[:greeks]
						if !contract_item_greeks.nil?
							optionchain_import.push(universe_id: universe_ids[c], quote: _quote, symbol: (contract_item[:symbol]).to_s, description: (contract_item[:description]).to_s, exch: (contract_item[:exch]).to_s, option_type: (contract_item[:option_type]).to_s, volume: (contract_item[:volume]), bid: (contract_item[:bid]), ask: (contract_item[:ask]), underlying: (contract_item[:underlying]).to_s, strike: (contract_item[:strike]), change_percentage: (contract_item[:change_percentage]), average_volume: (contract_item[:average_volume]), last_volume: (contract_item[:last_volume]), bidsize: (contract_item[:bidsize]), asksize: (contract_item[:asksize]), open_interest: (contract_item[:open_interest]), expiration_date: (contract_item[:expiration_date]).to_s, expiration_type: (contract_item[:expiration_type]).to_s, root_symbol: (contract_item[:root_symbol]).to_s, bid_iv: (contract_item_greeks[:bid_iv]), mid_iv: (contract_item_greeks[:mid_iv]), ask_iv: (contract_item_greeks[:ask_iv]) )
						else
							optionchain_import.push(universe_id: universe_ids[c], quote: _quote,  symbol: (contract_item[:symbol]).to_s, description: (contract_item[:description]).to_s, exch: (contract_item[:exch]).to_s, option_type: (contract_item[:option_type]).to_s, volume: (contract_item[:volume]), bid: (contract_item[:bid]), ask: (contract_item[:ask]), underlying: (contract_item[:underlying]).to_s, strike: (contract_item[:strike]), change_percentage: (contract_item[:change_percentage]), average_volume: (contract_item[:average_volume]), last_volume: (contract_item[:last_volume]), bidsize: (contract_item[:bidsize]), asksize: (contract_item[:asksize]), open_interest: (contract_item[:open_interest]), expiration_date: (contract_item[:expiration_date]).to_s, expiration_type: (contract_item[:expiration_type]).to_s, root_symbol: (contract_item[:root_symbol]).to_s )
						end
					end

					if !optionchain_import.empty?
						Optionchain.import optionchain_import
						optionchain_import = Array[]
					end	
				end			
				#####################


			rescue StandardError, NameError, NoMethodError, RuntimeError => e
				p "Error getting options " 
				p "Rescued: #{e.inspect}"
			else
			ensure
				optionchain_import = Array[]
			end


			c = c + 1

		end

		update_optiondowload_log("option_chain_download","Finished", c)

	end


	def calculate_spreads_main_loop
		#Variables
		c = 0
		strategies_list = ["call-debit"]
		jump = "30.0"
		maxrisk = "450.0"
		minreward = "5.0"
		minrr = "1.2"

		update_optiondowload_log("calculate_spreads","Started", c)
		
		#Delete all existing calculations from database
		p "Number of scenarios deleted : " + (Optionscenario.delete_all).to_s


		#Extract all underlying symbols, fast
		all_underlyings = Optionchain.pluck(:root_symbol).uniq
		#all_oc = Optionchain.all
		#####################################

		#Retrieve option chains from DB for a given underlying
		all_underlyings.each do |au|
			scenario_import = Array[]

			p c.to_s + ". " + au.to_s
			
			begin

				#oc = all_oc.select{ |a| a['root_symbol']==au}
				#oc = Optionchain.where(root_symbol: au)
				oc = Optionchain.find_by_sql(
				      "SELECT
				         *
				       FROM optionchains
				       WHERE optionchains.root_symbol='" + au.to_s + "'"
				       )
				

				#extract expiry dates array from option chain
				e_dates = oc.pluck(:expiration_date).uniq
				#p e_dates
				quotes = oc.pluck(:quote).uniq
				#p quotes[0]


				#Loop through strategies_list
				strategies_list.each do |s|
					p s
					cs = Calculatespreads.new(oc,quotes[0], au, e_dates, s, -1, jump, maxrisk, minreward, minrr )	
					ar = cs.analysis_results
					##Store Spreads Scenarios in an temp variable scenario_import
					if !ar.empty? 
						ar.each do |scenario|
							scenario_import.push(strategy: s.to_s, underlying: au, quote: quotes[0],  expiry_date: (scenario[:expiry_date]).to_s, buy_strike: (scenario[:buy_strike]), sell_strike: (scenario[:sell_strike]), risk: (scenario[:risk]), reward: (scenario[:reward]), rr_ratio: (scenario[:rr_ratio]), perc_change: (scenario[:perc_change]), buy_contract_symbol: (scenario[:buy_contract_symbol]).to_s, sell_contract_symbol: (scenario[:sell_contract_symbol]).to_s, buy_contract_iv: (scenario[:buy_contract_iv]), sell_contract_iv: (scenario[:sell_contract_iv])  )
						end
					end	

				end

				#Push to DB
				if !scenario_import.empty?
					Optionscenario.import scenario_import
					scenario_import = Array[]
				end			

			rescue StandardError, NameError, NoMethodError, RuntimeError => e
				p "Error getting options " 
				p "Rescued: #{e.inspect}"
			else
			ensure
				scenario_import = Array[]
			end

			c = c + 1
		end

		update_optiondowload_log("calculate_spreads","Finished", c)

	end


	def calculate_put_sells
		#Variables
		c = 0
		maxstrike = 30.0
		max_strike_to_quote = 0.95
		
		update_optiondowload_log("calculate_put_sells","Started", c)
		
		#Delete all existing options put sell calculations from database
		p "Number of options put sells scenarios deleted : " + (Optionputsell.delete_all).to_s


		#Extract all underlying symbols, fast
		all_underlyings = Optionchain.pluck(:root_symbol).uniq
		#all_oc = Optionchain.all
		#####################################

		#Retrieve option chains from DB for a given underlying
		all_underlyings.each do |au|
			putsell_import = Array[]

			p c.to_s + ". " + au.to_s
			
			begin

				#oc = all_oc.select{ |a| a['root_symbol']==au}
				#oc = Optionchain.where(root_symbol: au)
				oc = Optionchain.find_by_sql(
				      "SELECT
				         *
				       FROM optionchains
				       WHERE optionchains.root_symbol='" + au.to_s + "'"
				       )


				#Filter relevant contracts with strike and quote filters, then Calculate premium ratio
				ar = oc.select { |o| o.underlying==au and o.bid>0.1 and o.option_type=="put" and o.strike<=maxstrike and o.strike<o.quote and o.strike/o.quote < max_strike_to_quote}
				
				##Store calcs an temp variable scenario_import
				if !ar.empty? 
					ar.each do |scenario|
						premium_ratio = scenario[:bid] / scenario [:strike]
						putsell_import.push(underlying: au, optionsymbol: scenario[:symbol], expiry_date: scenario[:expiration_date], quote: scenario[:quote], strike: scenario[:strike], bid: scenario[:bid], ask: scenario[:ask], premiumratio: premium_ratio, option_type: scenario[:option_type])
					end
				end	

				

				#Push to DB
				if !putsell_import.empty?
					Optionputsell.import putsell_import
					putsell_import = Array[]
				end			

			rescue StandardError, NameError, NoMethodError, RuntimeError => e
				p "Error calculating put sells " 
				p "Rescued: #{e.inspect}"
			else
			ensure
				putsell_import = Array[]
			end

			c = c + 1
		end

		update_optiondowload_log("calculate_put_sells","Finished", c)

	end


	def update_optiondowload_log(activity,update_type, count)
		p update_type + " " + count.to_s + " underlyings at " + (DateTime.now()).to_s
		uol = Updateoptionlog.new(activity, update_type, (DateTime.now()), count)
	end




	


end