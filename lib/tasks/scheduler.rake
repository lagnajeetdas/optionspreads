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


task :download_stock_quotes => :environment do
  puts "Download stock quotes from tradier and saving to DB..."
    StockquoteDownloadJob.perform_later("download_stock_quotes")
  puts "done."
end

task :calculate_options_spreads => :environment do
  puts "Compute option spreads using saved data from db..."
    OptionsStragizerJob.perform_later
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
