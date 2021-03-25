desc "This task is called by the Heroku scheduler add-on"
task :download_stocksuniverse => :environment do
  puts "Getting stocks from finnhub..."
  	StockquoteDownloadJob.perform_later("universe")
  puts "done."
end

task :download_stockrecommendations => :environment do
  puts "Getting analyst recommendations from finnhub..."
  	StockquoteDownloadJob.perform_later("recommendation")
  puts "done."
end

task :download_stockmetadata => :environment do
  puts "Getting stock metadata from finnhub..."
  	StockquoteDownloadJob.perform_later("metadata")
  puts "done."
end

task :download_optionchains => :environment do
  puts "Getting option chains from tradier..."
  	StockquoteDownloadJob.perform_later("refresh_options")
  puts "done."
end




task :get_option_chains_entire_universe => :environment do
  puts "Getting option chains from tradier for universe..."
    OptionsGetterJob.perform_later("get")
  puts "done."
end

task :calculate_spreads => :environment do
  puts "Compute option spreads using saved option chain data from db..."
    OptionsGetterJob.perform_later("calculate_spreads")
  puts "done."
end

task :calculate_put_sells => :environment do
  puts "Compute put sells using saved option chain data from db..."
    OptionsGetterJob.perform_later("calculate_put_sells")
  puts "done."
end




task :download_stock_quotes => :environment do
  puts "Download stock quotes from tradier and saving to DB..."
    StockquoteDownloadJob.perform_later("download_stock_quotes")
  puts "done."
end


task :calculate_high_open_interest_options => :environment do
  puts "Select top 500 open interest options and save to db to serve to client fast..."
    OptionsStragizerJob.perform_later("calc_high_open_interests")
  puts "done."
end

task :calculate_top_option_spreads => :environment do
  puts "Select top 500 top option spreads and save to db to serve to client fast..."
    OptionsStragizerJob.perform_later("calc_top_option_spreads")
  puts "done."
end

task :get_targets_largecap => :environment do
  puts "Download targets from alphavantage..."
    StockquoteDownloadJob.perform_later("get_targets_largecap")
  puts "done."
end

task :get_targets_midcap => :environment do
  puts "Download targets from alphavantage..."
    StockquoteDownloadJob.perform_later("get_targets_midcap")
  puts "done."
end

task :get_targets_smallcap => :environment do
  puts "Download targets from alphavantage..."
    StockquoteDownloadJob.perform_later("get_targets_smallcap")
  puts "done."
end

task :get_earnings => :environment do
  puts "Downloading earnings calendar at one go from finnhub."
    StockquoteDownloadJob.perform_later("earningscalendar")
  puts "done."
end



#delete tasks

task :clear_oldoptions => :environment do
  puts "Cleaning up old options from the db..."
    StockquoteDownloadJob.perform_later("clear_oldoptions")
  puts "done."
end

task :delete_alloptionchains => :environment do
  puts "Cleaning up all options from the db..."
    StockquoteDownloadJob.perform_later("delete_all_options")
  puts "done."
end

task :delete_stockprofiles_conditional => :environment do
  puts "Cleaning up selected stock profiles from the db..."
    StockquoteDownloadJob.perform_later("delete_stockprofiles")
  puts "done."
end

task :delete_all_recommendations => :environment do
  puts "Cleaning recommendations the db..."
    StockquoteDownloadJob.perform_later("delete_recommendations")
  puts "done."
end

task :delete_old_option_spreads => :environment do
  puts "Cleaning up old option spreads..."
    OptionsStragizerJob.perform_later("delete_old_option_spreads")
  puts "done."
end
