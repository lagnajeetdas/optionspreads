class Logusersearch

	def initialize(ticker,user)

		us = Usersearch.new(symbol: ticker, who: user)
		us.save
		
	end


end