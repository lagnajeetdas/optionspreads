class HomeController < ApplicationController
  def index
  	@api = StockQuote::Stock.new(api_key: 'pk_34bbabe4cf054befa331a42b695e75b2')
  	
  	if params[:ticker] == ""
  		@nothing = "Hey, You forgot to enter a symbol"
  	elsif params[:ticker]

    	begin
  		    @stock = StockQuote::Stock.quote(params[:ticker])
  		rescue RuntimeError
  		    @error =  "Hey, That stock symbol doesn't exit. Please try again"
      rescue NoMethodError
          @error =  "Hey, The symbol exists but we cannot fetch the quote. Please try NYSE/NASDAQ tickers. "
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
