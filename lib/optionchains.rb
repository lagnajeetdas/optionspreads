class Optionchains
	require 'httparty'
    require 'json'
    require 'filtermainexpirydates'
	
	def initialize(symbol, e_dates)
		@symbol = symbol
		
		@optionchain_import = Array[]
		@baseurl_tradier = ENV['baseurl_tradier']
		@tradier_api_key = ENV['tradier_api_key']

		
		@e_dates = e_dates
		

		if @e_dates.kind_of?(Array)
			@e_dates.each do |item|
				apicall_optionchains(item)
			end
		else
			apicall_optionchains(@e_dates.to_s)
		end
	end

	def apicall_optionchains(expirydate)
		begin 
 	
		  	#api call to tradier to fetch option chains for a selected expiry date and underlying
		  	url_options_chain_string = @baseurl_tradier + "options/chains?symbol=" + @symbol + "&expiration=" + expirydate + "&greeks=true"
			response = HTTParty.get(url_options_chain_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})

			if response.code == 200 #valid response
				if response.parsed_response['options']['option']
					optionchain_data = response.parsed_response['options']['option']
					
					if !optionchain_data.empty?
						#@optionchain_import.push(optionchain_data)
						if 1==1
							#then save to DB model
								optionchain_data.each do |contract_item|
									contract_item_greeks = contract_item['greeks']
									if !contract_item_greeks.nil?
										@optionchain_import.push({symbol: (contract_item['symbol']).to_s, description: (contract_item['description']).to_s, exch: (contract_item['exch']).to_s, option_type: (contract_item['option_type']).to_s, volume: (contract_item['volume']), bid: (contract_item['bid']), ask: (contract_item['ask']), underlying: (contract_item['underlying']).to_s, strike: (contract_item['strike']), change_percentage: (contract_item['change_percentage']), average_volume: (contract_item['average_volume']), last_volume: (contract_item['last_volume']), bidsize: (contract_item['bidsize']), asksize: (contract_item['asksize']), open_interest: (contract_item['open_interest']), expiration_date: (contract_item['expiration_date']).to_s, expiration_type: (contract_item['expiration_type']).to_s, root_symbol: (contract_item['root_symbol']).to_s, bid_iv: (contract_item_greeks['bid_iv']), mid_iv: (contract_item_greeks['mid_iv']), ask_iv: (contract_item_greeks['ask_iv']) })
									else
										@optionchain_import.push({symbol: (contract_item['symbol']).to_s, description: (contract_item['description']).to_s, exch: (contract_item['exch']).to_s, option_type: (contract_item['option_type']).to_s, volume: (contract_item['volume']), bid: (contract_item['bid']), ask: (contract_item['ask']), underlying: (contract_item['underlying']).to_s, strike: (contract_item['strike']), change_percentage: (contract_item['change_percentage']), average_volume: (contract_item['average_volume']), last_volume: (contract_item['last_volume']), bidsize: (contract_item['bidsize']), asksize: (contract_item['asksize']), open_interest: (contract_item['open_interest']), expiration_date: (contract_item['expiration_date']).to_s, expiration_type: (contract_item['expiration_type']).to_s, root_symbol: (contract_item['root_symbol']).to_s })
									end								
								end
						end
						
					end
				end
			end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Error for " + @symbol + " exp date " + expirydate.to_s
			p e.backtrace
			p response
			#p "Rescued: #{e.inspect}"
			#p e.backtrace
		else

		ensure

		end
	end

	def chains

		@optionchain_import
	end




	

end
