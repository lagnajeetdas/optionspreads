class OptionsGetterJob < ApplicationJob
	require 'optionexpirydates'
  	require 'optionchains'
  	require 'livequotetradier'
  	require 'date'

	def perform(service)
		main_loop
	end

	def main_loop
		#Variables
		c = 1
		max_num_e_dates = 4

		#Log the start time of download
		update_optiondowload_log("Started", c)

		#Extract all symbols in Universe, fast	
		universes = Universe.pluck(:displaysymbol)

		#loop through each underlying in universe 
		universes.take(20).each do |u|
			p c.to_s + ". " + u.to_s

			begin
				#declare default values of temp variables
				quote = -1
				e_dates = Array[]

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
				#####################


			rescue StandardError, NameError, NoMethodError, RuntimeError => e
				p "Error calculating spreads " 
				p "Rescued: #{e.inspect}"
			else
			ensure
			end


			c = c + 1

		end

		update_optiondowload_log("Finished", c)

	end



	def update_optiondowload_log(update_type, count)
		p update_type + count.to_s + " underlyings at " + (DateTime.now()).to_s
	end

	


end