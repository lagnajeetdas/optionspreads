class HomeController < ApplicationController
  def index
  	@api = StockQuote::Stock.new(api_key: 'pk_1f25165af56b44c6a0e3a2b713eefba4')
  	
  	if params[:ticker] == ""
  		@nothing = "Hey, You forgot to enter a symbol"
  	elsif params[:ticker]

    	begin
  		    @stock = StockQuote::Stock.quote(params[:ticker])
  		rescue RuntimeError
  		    @error =  "Hey That stock symbol doesn't exit. Please try again"
  		else
  		    p "No error"	 
    		ensure
    			p "Done"	    
  		end

  	end
  end

  def about
  end

end
