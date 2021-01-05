class Earningsdate

	def initialize(year, start_month)
		@year = year
		@start_month = start_month
		@finnhub_baseurl_3 = "https://finnhub.io/api/v1/"
		@finnhub_api_key_prod = "bv1u7mf48v6o5ed6gpd0"
		@start_date = ""
		@end_date = ""
		@earningsdate_ary = Array[]
		calc_start_end_date
		earnings_api_call
	end

	def calc_start_end_date
		@start_date = @year.to_s + "-" + @start_month.to_s.rjust(2, "0") + "-01"

		if @start_month.to_i > 10
			@end_date = (@year.to_i+1).to_s + "-" + (2 + @start_month.to_i - 12).to_s.rjust(2, "0") + "-31"
		else
			@end_date = @year.to_s + "-" + (@start_month.to_i + 2).to_s.rjust(2, "0") + "-31"
		end

	end

	def earnings_api_call
		#https://finnhub.io/api/v1/calendar/earnings?from=2021-01-01&to=2021-03-31&token=bv1u7mf48v6o5ed6gpd0
		
		url_finnhub_earningdates = @finnhub_baseurl_3 + "calendar/earnings?=from=" + @start_date + "&to" + @end_date + "&token=" + @finnhub_api_key_prod
		response = HTTParty.get(url_finnhub_earningdates)

		if response.code == 200
			if response.parsed_response["earningsCalendar"]
			  	@earningsdate_ary = response.parsed_response["earningsCalendar"]

			  	if !@earningsdate_ary.empty?
				  	@earningsdate_ary.each do |ed|
				  		begin 
					  		Stockprofile.find_by(symbol: ed['symbol']).update_column(:next_earnings_date, ed['date'])
						  	p "earnings date saved " + (ed['symbol']).to_s	
						rescue StandardError, NameError, NoMethodError, RuntimeError => e
							
							p "Error saving earnings date.."
							p "Rescued: #{e.inspect}"
						end  		
				  	end
				end
			end
		else
			p "Response code 400"
		end

	end

	def earnings
		@earningsdate_ary
	end

end
