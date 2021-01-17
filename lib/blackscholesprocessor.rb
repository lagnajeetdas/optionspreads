class Blackscholesprocessor
	require 'rubygems'
	require 'options_library'
	require 'date'


	def initialize(symbol, quote, e_date, long_iv, short_iv, dividend, long_strike, short_strike, strategy, entry_cost)
		@symbol = symbol
		@quote = quote.to_f
		@e_date = e_date
		@long_iv = long_iv.to_f
		@short_iv = short_iv.to_f
		@iv = (@long_iv + @short_iv)/2
		@interest = 0.01
		@dividend = dividend.to_f
		@long_strike = long_strike.to_f
		@short_strike = short_strike.to_f
		@strategy = strategy
		@entry_cost = entry_cost.to_f

		create_time_strike_price_grid
	end



	def create_time_strike_price_grid
		#create a hash of days, strike and price

		#initialize days and price ranges
		num_days_till_e_date = (Date.parse(@e_date) - Date.today).to_i
		ceiling_price = ([@long_strike, @short_strike].max) * 1.2
		floor_price = ([@long_strike, @short_strike, @quote].min) * 0.8
		step_price = 0.05 * (@quote).to_f
		p = 0.0
		@grid = Array []
		@days = Array []
		@strikes = Array []
		@labeled_dates = Array []
		@labeled_months = Array []

		#iterate over days
		r = num_days_till_e_date..0
		(r.first).downto(r.last).each do |d| 
		#(0..num_days_till_e_date).each do |d|

			d_years = (d.to_f)/365
			@days.push(d)
			
			#get labeled months
			x = Date.today + (num_days_till_e_date-d)
			@labeled_months.push(x.strftime("%b"))

			#get labeled days
			@labeled_dates.push(x.strftime("%-d"))			


			#iterate over strike range to calculate option pricing
			(floor_price..ceiling_price).step(step_price) do |s|
				s = s.round(2)
				#option library gem calculator
				@strikes.push(s)
				buy_p = Option::Calculator.price_call( s, @long_strike, d_years, @interest, @iv, @dividend ) 
				sell_p = Option::Calculator.price_call( s, @short_strike, d_years, @interest, @iv, @dividend ) 
				closing_p = (buy_p - sell_p) * 100
				profit = (closing_p - @entry_cost).round(0)
				profit_perc = ((profit/@entry_cost) * 100).round(2)
				buy_p = buy_p.round(2)
				sell_p = sell_p.round(2)
				upside_perc = (((s-@quote)/@quote)*100).round(1)
				

				price_hash = {"days" => d, "strike" => s,  "results" => { "closing" => closing_p, "buy_p" => buy_p, "sell_p" => sell_p, "profit" => profit, "profit_perc" => profit_perc,  "quote" => @quote, "upside_perc" => upside_perc   }}

				@grid.push(price_hash)
			end
		end

	end

	def price_grid
		@grid
	end

	def days_array
		@days
	end

	def strikes_array
		@strikes
	end

	def labeled_months_array
		@labeled_months
	end

	def labeled_dates_array
		@labeled_dates
	end



end
