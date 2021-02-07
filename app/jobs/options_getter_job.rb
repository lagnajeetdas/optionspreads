class OptionsGetterJob < ApplicationJob
	require 'optionexpirydates'
  	require 'optionchains'
  	require 'livequotetradier'
  	require 'date'
  	require 'updateoptionlog'

	def perform(service)
		main_loop
	end

	def main_loop
		#Variables
		c = 0
		max_num_e_dates = 4

		#Log the start time of download
		update_optiondowload_log("Started", c)

		#Extract all symbols in Universe, fast	
		universes = Universe.pluck(:displaysymbol)
		universe_ids = Universe.pluck(:id)

		#loop through each underlying in universe 
		universes.each do |u|
			p c.to_s + ". " + u.to_s

			begin
				#declare default values of temp variables
				quote = -1
				e_dates = Array[]
				optionchain_import = Array[]

				##Get Live Stock Quote
				#lq = Livequotetradier.new(u)
				#quote = lq.latest_price
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
							optionchain_import.push(universe_id: universe_ids[c], symbol: (contract_item[:symbol]).to_s, description: (contract_item[:description]).to_s, exch: (contract_item[:exch]).to_s, option_type: (contract_item[:option_type]).to_s, volume: (contract_item[:volume]), bid: (contract_item[:bid]), ask: (contract_item[:ask]), underlying: (contract_item[:underlying]).to_s, strike: (contract_item[:strike]), change_percentage: (contract_item[:change_percentage]), average_volume: (contract_item[:average_volume]), last_volume: (contract_item[:last_volume]), bidsize: (contract_item[:bidsize]), asksize: (contract_item[:asksize]), open_interest: (contract_item[:open_interest]), expiration_date: (contract_item[:expiration_date]).to_s, expiration_type: (contract_item[:expiration_type]).to_s, root_symbol: (contract_item[:root_symbol]).to_s, bid_iv: (contract_item_greeks[:bid_iv]), mid_iv: (contract_item_greeks[:mid_iv]), ask_iv: (contract_item_greeks[:ask_iv]) )
						else
							optionchain_import.push(universe_id: universe_ids[c], symbol: (contract_item[:symbol]).to_s, description: (contract_item[:description]).to_s, exch: (contract_item[:exch]).to_s, option_type: (contract_item[:option_type]).to_s, volume: (contract_item[:volume]), bid: (contract_item[:bid]), ask: (contract_item[:ask]), underlying: (contract_item[:underlying]).to_s, strike: (contract_item[:strike]), change_percentage: (contract_item[:change_percentage]), average_volume: (contract_item[:average_volume]), last_volume: (contract_item[:last_volume]), bidsize: (contract_item[:bidsize]), asksize: (contract_item[:asksize]), open_interest: (contract_item[:open_interest]), expiration_date: (contract_item[:expiration_date]).to_s, expiration_type: (contract_item[:expiration_type]).to_s, root_symbol: (contract_item[:root_symbol]).to_s )
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

		update_optiondowload_log("Finished", c)

	end



	def update_optiondowload_log(update_type, count)
		p update_type + count.to_s + " underlyings at " + (DateTime.now()).to_s
		uol = Updateoptionlog.new("option_chain_download", update_type, (DateTime.now()), count)
	end

	


end