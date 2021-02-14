class TargetGetterJob < ApplicationJob
  require 'acquiretarget'

	def perform(symbols)
		gettarget_bulk(symbols)
	end

  def gettarget_bulk(_tickers)
  
  	@queue = Limiter::RateQueue.new(5, interval: 60) #API throttling setup 5 calls / minute
    #loop through all tickers to query target price and store in DB
    _tickers.each do |t|
    	begin
    		@queue.shift #API throttling block starts here
			at = Acquiretarget.new(t)
			analyst_target_price = at.get_target
			if !analyst_target_price.nil?

				#store in user's stock db
				Stock.find_by(ticker: t).update_column(:target_price_auto, analyst_target_price.to_f)

				#store in stock universe db
				Universe.find_by(displaysymbol: t).update_column(:target_price, analyst_target_price.to_f)

				p "updated target price in db for " + t.to_s
			else
				p "No target price available for " + t.to_s
			end
		rescue StandardError, NameError, NoMethodError, RuntimeError => e
	        p "Error getting targets in bulk .." + t.to_s
	        p "Rescued: #{e.inspect}"
	    else
	    ensure
	    end

    end


  end

end