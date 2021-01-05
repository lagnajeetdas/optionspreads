class Acquiretarget

	def initialize(symbol)

		@symbol = symbol
		@analyst_target_price = nil
		@error_message = ""

		target_api_call
	end


	def target_api_call
	    # Call Alpha vantage API company profile to get target price
	    # https://www.alphavantage.co/query?function=OVERVIEW&symbol=LAZR&apikey=UQLYHKP646RJWFJ3
	    baseurl_alphavantage = "https://www.alphavantage.co/query?"
	    alphavantage_apikey = "UQLYHKP646RJWFJ3"
	    
	    url_alphavantage_company = baseurl_alphavantage + "function=OVERVIEW&symbol=" + @symbol + "&apikey=" + alphavantage_apikey

	    response = HTTParty.get(url_alphavantage_company)
	    analyst_target_price = "None"

	    if response.code == 200
	      if response.parsed_response['AnalystTargetPrice'] 
	      	@analyst_target_price = response.parsed_response['AnalystTargetPrice'] 
	      else
	      	@error_message = "No target price available from alphavantage"
	      end
	    else
	    	@error_message = "Reponse not 200"
	    end
	  
	end

	def get_target
		if @analyst_target_price
			(@analyst_target_price).to_f
		else
			nil
		end
	end

	def get_target_error
		(@error_message).to_s
	end



end