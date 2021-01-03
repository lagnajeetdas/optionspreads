class Livequotetradier
    attr_accessor :symbol, :tradier_api_key, :baseurl_tradier, :url_stock_quote_string

    def initialize(symbol)
    	@symbol = symbol
      @stockprofiles = Stockprofile.all
    
      api_call
   	end

    def test_initialize
      p @symbol
    end

    def api_call
      tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
      baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"

    
      url_stock_quote_string = baseurl_tradier.to_s + "quotes?symbols=" + @symbol.to_s
      response = HTTParty.get(url_stock_quote_string, {headers: {"Authorization" => 'Bearer ' + tradier_api_key.to_s}})
      if response.code == 200
        if response.parsed_response['quotes']['quote']
              symbols_quotes = response.parsed_response['quotes']['quote']
              @q = symbols_quotes 
              
        #@ticker.push("company_name" => q["description"], "latest_price" => q['last'], "symbol" => q['symbol'], "change_percent" => q['change_percentage'], "week52_high" => q['week_52_high'], "week52_low" => q['week_52_low'])
              
          else
          p "did not find quotes using Tradier API"
          end
      else
          p "Tradier API did not respond sucessfully"
      end
      
    end

    def company_name
      (@q['description']).to_s
    end

    def latest_price
      (@q['last']).to_f
    end

    def symbol
      (@q['symbol']).to_s
    end

    def change_percent
      (@q['change_percentage']).to_f
    end

    def week52_high
      (@q['week_52_high']).to_f
    end

    def week52_low
      (@q['week_52_low']).to_f
    end


    #def logo
    #  (@stockprofiles.select{|s| s['symbol']==@symbol })[0]['logo']
    #end

   	

end
