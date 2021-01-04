class Blackscholesprocessor

	def initialize(symbol, quote, e_date, iv, dividend, long_strike, short_strike, strategy)
		@symbol = symbol
		@quote = quote
		@e_date = e_date
		@iv = iv
		@interest = 0.01
		@dividend = dividend
		@long_strike = long_strike
		@short_strike = short_strike
		@strategy = strategy
	end

	def create_time_strike_price_grid
		

	end



end
