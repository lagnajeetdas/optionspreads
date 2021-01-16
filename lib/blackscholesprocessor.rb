class Blackscholesprocessor
	require 'rubygems'
	require 'options_library'


	def initialize(symbol, quote, e_date, iv, dividend, long_strike, short_strike, strategy, entry_cost)
		@symbol = symbol
		@quote = quote.to_f
		@e_date = e_date
		@iv = iv.to_f
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

		#iterate over days
		r = num_days_till_e_date..0
		(r.first).downto(r.last).each do |d| 
		#(0..num_days_till_e_date).each do |d|
			d_years = (d/365)
			@days.push(d)
			#iterate over strike range to calculate option pricing
			(floor_price..ceiling_price).step(step_price) do |s|
				s = s.round(2)
				#option library gem calculator
				@strikes.push(s)
				buy_p = Option::Calculator.price_call( s, @long_strike, d, @interest, @iv, @dividend ) 
				sell_p = Option::Calculator.price_call( s, @short_strike, d, @interest, @iv, @dividend ) 
				closing_p = (buy_p - sell_p) * 100
				profit = (closing_p - @entry_cost).round(0)
				profit_perc = ((profit/@entry_cost) * 100).round(2)

				#price_hash = {:days => d, :results => { :strike => s, :closing => closing_p, :buy_p => buy_p, :sell_p => sell_p, :profit => profit }}
				price_hash = {"days" => d, "strike" => s,  "results" => { "closing" => closing_p, "buy_p" => buy_p, "sell_p" => sell_p, "profit" => profit, "profit_perc" => profit_perc }}

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



end
