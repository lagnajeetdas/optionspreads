class OptionbookmarksController < ApplicationController
  before_action :set_optionbookmark, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit,:update, :destroy]
  before_action :authenticate_user!

  # GET /optionbookmarks
  # GET /optionbookmarks.json
  def index
    @optionbookmarks = Optionbookmark.all
  end

  # GET /optionbookmarks/1
  # GET /optionbookmarks/1.json
  def show
  end

  # GET /optionbookmarks/new
  def new
    @optionbookmark = Optionbookmark.new
  end

  # GET /optionbookmarks/1/edit
  def edit
  end

  # POST /optionbookmarks
  # POST /optionbookmarks.json
  def create
    @optionbookmark = Optionbookmark.new(optionbookmark_params)

    respond_to do |format|
      if @optionbookmark.save
        format.html { redirect_to @optionbookmark, notice: 'Optionbookmark was successfully created.' }
        format.json { render :show, status: :created, location: @optionbookmark }
      else
        format.html { render :new }
        format.json { render json: @optionbookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /optionbookmarks/1
  # PATCH/PUT /optionbookmarks/1.json
  def update
    respond_to do |format|
      if @optionbookmark.update(optionbookmark_params)
        format.html { redirect_to @optionbookmark, notice: 'Optionbookmark was successfully updated.' }
        format.json { render :show, status: :ok, location: @optionbookmark }
      else
        format.html { render :edit }
        format.json { render json: @optionbookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /optionbookmarks/1
  # DELETE /optionbookmarks/1.json
  def destroy
    @optionbookmark.destroy
    respond_to do |format|
      format.html { redirect_to optionbookmarks_url, notice: 'Optionbookmark was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def correct_user
    @bookmark = current_user.optionbookmarks.find_by(id: params[:id])
    redirect_to optionbookmarks_path, notice: "Not Authorized to edit this bookmark" if @bookmark.nil?
  end


  def addbookmark
    @longleg = params[:longleg]
    @shortleg = params[:shortleg]
    underlying = params[:underlying]
    e_date = params[:e_date]
    func = params[:func]

    p @longleg
    p @shortleg
    p current_user.id


    if Optionbookmark.find_by(shortleg: @shortleg, longleg: @longleg, user_id: current_user.id)
        @bookmark_flag = 0
        respond_to do |format|
            format.js
        end 
        Optionbookmark.find_by(shortleg: @shortleg, longleg: @longleg, user_id: current_user.id).destroy
        p "Deleted Bookmark"
    else
        @bookmark_flag = 1
        respond_to do |format|
          format.js
        end        
        ob = Optionbookmark.new(shortleg: @shortleg, longleg: @longleg, user_id: current_user.id, underlying: underlying, e_date: e_date)
        if ob.save
          p "Bookmarked"
          
        else
          p "Not bookmarked"
          @bookmark_flag = 0
          respond_to do |format|
            format.js
          end    
        end

    end

    p @bookmark_flag
    
    
    


  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_optionbookmark
      @optionbookmark = Optionbookmark.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def optionbookmark_params
      params.require(:optionbookmark).permit(:longleg, :shortleg, :user_id)
    end
end
