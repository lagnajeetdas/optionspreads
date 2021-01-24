class Optionexpirydates
	require 'httparty'
    require 'json'
	def initialize(symbol)
		@symbol = symbol
		@baseurl_tradier = ENV['baseurl_tradier']
		@tradier_api_key = ENV['tradier_api_key']

		apicall_e_dates
	end

	def apicall_e_dates
	  	begin 
		  	url_options_expiry_string = @baseurl_tradier + "options/expirations?symbol=" + @symbol + "&includeAllRoots=false&strikes=false"
			response = HTTParty.get(url_options_expiry_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})

			@expirydates_data = Array[]

			if response.code == 200

				if response.parsed_response['expirations']
					@expirydates_data = response.parsed_response['expirations']['date']
				end
			end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
			p "Rescued: #{e.inspect}"
			p e.backtrace
			
		else
		ensure
		end

	end


	def e_dates
		@expirydates_data
	end
end
