class StocksController < ApplicationController
  before_action :set_stock, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit,:update, :destroy]
  before_action :authenticate_user!
  require 'httparty'
  require 'json'
  require 'bootstrap-table-rails'
  require 'livequotetradier'
  require 'blackscholesprocessor'
  require 'optionexpirydates'
  require 'optionchains'
  require 'calculatespreads'

  # GET /stocks
  # GET /stocks.json
  def index
    
    @stocks = Stock.select{ |s| s['user_id']==current_user.id}
    @tickers = Array[]
    @recommendations = Recommendation.all



    @api = StockQuote::Stock.new(api_key: ENV['iexcloud_api_key'])
    @finnhub_api_key = ENV['finnhub_api_key']
    
    @iexcloud_api_key = ENV['iexcloud_api_key']
    @baseurl_iexcloud = "https://cloud.iexapis.com/stable/stock/"

    @tradier_api_key = ENV['tradier_api_key']
    @baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"

    get_watchlist_stocks_live_quotes



    #StockquoteDownloadJob.set(wait: 1.minute).perform_later
    #StockquoteDownloadJob.perform_later
    #StockquoteDownloadJob.perform_later("refresh_options")
    #StockquoteDownloadJob.perform_later("clear_oldoptions")
    #StockquoteDownloadJob.perform_later("delete_all_options")
    #StockquoteDownloadJob.perform_later("metadata")
    #StockquoteDownloadJob.perform_later("delete_stockprofiles")
    #StockquoteDownloadJob.perform_later("delete_recommendations")
  end

  # GET /stocks/1
  # GET /stocks/1.json
  def show
    require 'uri'
    require 'net/http'
    @tradier_api_key = ENV['tradier_api_key']
    @baseurl_tradier = ENV['baseurl_tradier'] # /options/expirations"
    @recommendations = Recommendation.all
    @bookmarks = Optionbookmark.select{ |o| o['user_id']==current_user.id}
    
    #get stock quotes and setup ticker
    begin
      @ticker = Livequotetradier.new(@stock.ticker)
      @ticker_logo  = (StockQuote::Stock.logo(@stock.ticker)).url
      if !@ticker
        p "ticker could not be fetched using tradier api"
        @ticker = StockQuote::Stock.quote(@stock.ticker)
      end

      if @ticker
        #Get expiry date of options with API
        options_e_dates = Optionexpirydates.new(@ticker.symbol)
        @expirydates_data = options_e_dates.e_dates
      end

    rescue StandardError, NameError, NoMethodError, RuntimeError => e
      p "Rescued: #{e.inspect}"
      p e.backtrace
      @ticker = nil
    else
    ensure
    end



      
  end

  # GET /stocks/new
  def new

    @stock = Stock.new
  end

  # GET /stocks/1/edit
  def edit
  end

  # POST /stocks
  # POST /stocks.json
  def create

    @stock = Stock.new(stock_params)
    @stock.ticker = params[:stock][:ticker].upcase

    respond_to do |format|
      if @stock.save
        format.html { redirect_to @stock, notice: 'Stock was successfully added to watchlist.' }
        format.json { render :show, status: :created, location: @stock }
      else
        format.html { render :new }
        format.json { render json: @stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stocks/1
  # PATCH/PUT /stocks/1.json
  def update
    respond_to do |format|
      if @stock.update(stock_params)
        format.html { redirect_to @stock, notice: 'Stock was successfully updated.' }
        format.json { render :show, status: :ok, location: @stock }
      else
        format.html { render :edit }
        format.json { render json: @stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stocks/1
  # DELETE /stocks/1.json
  def destroy
    @stock.destroy
    respond_to do |format|
      format.html { redirect_to stocks_url, notice: 'Stock was successfully deleted from watchlist.' }
      format.json { head :no_content }
    end
  end

  def correct_user
    @ticker = current_user.stocks.find_by(id: params[:id])
    redirect_to stocks_path, notice: "Not Authorized to edit this stock" if @ticker.nil?
  end

  def gettarget
    # Call Alpha vantage API company profile to get target price
    # https://www.alphavantage.co/query?function=OVERVIEW&symbol=LAZR&apikey=UQLYHKP646RJWFJ3
    @baseurl_alphavantage = "https://www.alphavantage.co/query?"
    @alphavantage_apikey = "UQLYHKP646RJWFJ3"
    symbol = params[:symbol]
    @url_alphavantage_company = @baseurl_alphavantage + "function=OVERVIEW&symbol=" + symbol + "&apikey=" + @alphavantage_apikey


    response = HTTParty.get(@url_alphavantage_company)
    @analyst_target_price = "None"

    p response
    p response.code

    if response.code == 200
      @analyst_target_price = response.parsed_response['AnalystTargetPrice'] 
    end

    p @analyst_target_price

    if @analyst_target_price.nil?
      @analyst_target_price = "None" # because not sure how to make JS ERB handle nil
    end

    respond_to do |format|
        format.js
    end

    if @analyst_target_price!="None"
      Stock.find_by(ticker: params[:symbol]).update_column(:target_price_auto, @analyst_target_price.to_f)
      p "updated in db"
    end

   
  end

  def compute_buy_rating
    symbol = params[:symbol]
    reco = Array[]
    reco = @recommendations.select{|r| r['symbol']==symbol.to_s}
    
    if !reco.empty?
      num_buy = reco[0]['buy']
      num_strongbuy reco[0]['strongbuy']
      num_sell = reco[0]['sell']
      num_strongsell = reco[0]['strongsell']
      num_hold = reco[0]['hold']

      num_total_ratings = num_buy + num_strongbuy + num_sell + num_strongsell + num_hold
      @buy_rating = round(100 * ((num_buy + num_strongbuy)/num_total_ratings),1)
    end


  end



  def get_watchlist_stocks_live_quotes


      last_page = ((@stocks.count)/25)+1
      (1..last_page).each do |p|  
        symbols_arr = Kaminari.paginate_array(@stocks.pluck(:ticker))
        symbols = symbols_arr.page(p).per(25)  #tested till 25.. can it be increased?
        symbols = symbols.map!(&:upcase)
        symbols_string = symbols.join(",")
        
        begin
          url_stock_quote_string = @baseurl_tradier + "quotes?symbols=" + symbols_string
          response = HTTParty.get(url_stock_quote_string, {headers: {"Authorization" => 'Bearer ' + @tradier_api_key}})
            if response.code == 200 
              if response.parsed_response['quotes']['quote']
                symbols_quotes = response.parsed_response['quotes']['quote']
                symbols_quotes.each do |q|
                  #p q['description']
                  #p q['last']
                  @tickers.push("company_name" => q["description"], "latest_price" => q['last'], "symbol" => q['symbol'])
                end
              else
                p "did not find quotes - quote for " + symbols_string.to_s
              end
            else
              p "API did not respond sucessfully for  " + symbols_string.to_s
            end
        rescue StandardError, NameError, NoMethodError, RuntimeError => e
          p "Error getting quotes .."
          p "Rescued: #{e.inspect}"

        end
      end
  end

  


  def get_roi_json(pg)
    p pg
    #render json: {status: 'SUCCESS', message: 'Loaded all posts', data: pg}, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stock
      @stock = Stock.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stock_params
      params.require(:stock).permit(:ticker, :user_id, :target_price_auto)
    end
end
