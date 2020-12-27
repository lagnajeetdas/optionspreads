class StocksController < ApplicationController
  before_action :set_stock, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit,:update, :destroy]
  before_action :authenticate_user!
  require 'httparty'
  require 'json'
  require 'bootstrap-table-rails'




  # GET /stocks
  # GET /stocks.json
  def index
    
    @stocks = Stock.all

    @api = StockQuote::Stock.new(api_key: 'pk_34bbabe4cf054befa331a42b695e75b2')
    @finnhub_api_key = "sandbox_bv1u7mf48v6o5ed6gpdg"
    
    @iexcloud_api_key = "pk_34bbabe4cf054befa331a42b695e75b2"
    @baseurl_iexcloud = "https://cloud.iexapis.com/stable/stock/"

    #StockquoteDownloadJob.set(wait: 1.minute).perform_later
    #StockquoteDownloadJob.perform_later
    
  end

  # GET /stocks/1
  # GET /stocks/1.json
  def show
    require 'uri'
    require 'net/http'
    @tradier_api_key = "iBjlJhQDEEBh4FIawWLCRyUJAgaP"
    @baseurl_tradier = "https://sandbox.tradier.com/v1/markets/" # /options/expirations"





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

    respond_to do |format|
      if @stock.save
        format.html { redirect_to @stock, notice: 'Stock was successfully created.' }
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
      format.html { redirect_to stocks_url, notice: 'Stock was successfully deleted.' }
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
