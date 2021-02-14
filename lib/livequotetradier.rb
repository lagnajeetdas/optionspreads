class Livequotetradier
    attr_accessor :symbol, :tradier_api_key, :baseurl_tradier, :url_stock_quote_string

    def initialize(symbol, store_in_DB = 0)
    	@symbol = symbol
      #@stockprofiles = Stockprofile.all
      
      if store_in_DB==0
        api_call
      else
        api_call_and_store_in_DB
      end

   	end

    def test_initialize
      p @symbol
    end

    def api_call
      tradier_api_key = ENV['tradier_api_key']
      baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"

    
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

    def api_call_and_store_in_DB

        tradier_api_key = ENV['tradier_api_key']
        baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"

        begin
          #first delete all existing quotes from Stockprice database
          p Stockprice.delete_all

          #paginate and execute API
          num_symbols_per_page = 50
          last_page = ((@symbol.count)/num_symbols_per_page)+1
          (1..last_page).each do |p|  
            symbols_arr = Kaminari.paginate_array(@symbol)
            symbols = symbols_arr.page(p).per(num_symbols_per_page)  #tested till 25.. can it be increased?
            symbols = symbols.map!(&:upcase)
            symbols_string = symbols.join(",")
            #p symbols_string
            url_stock_quote_string = baseurl_tradier + "quotes?symbols=" + symbols_string
            response = HTTParty.get(url_stock_quote_string, {headers: {"Authorization" => 'Bearer ' + tradier_api_key}})
            if response.code == 200 
              if response.parsed_response['quotes']['quote']
                symbols_quotes = response.parsed_response['quotes']['quote']
                symbols_quotes.each do |q|
                  #Stockprice.where(symbol: q['symbol']).delete_all
                  stockprices = Stockprice.new(symbol: q['symbol'], last: q['last'])
                  if stockprices.save
                    p "saved live quote to db " + q['symbol']
                  else
                    p "did not save live quote to db " + q['symbol']
                  end
                end
              else
                p "did not find quotes - quote for " + symbols_string.to_s
              end
            else
              p "Live Quote Tradier API did not respond sucessfully for  " + symbols_string.to_s

            end
          end
          

        rescue StandardError, NameError, NoMethodError, RuntimeError => e
          p "Error downloading stock prices and storing in db .."
          #p response
          p "Rescued: #{e.inspect}"
          #p e.backtrace

        else

        ensure

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
