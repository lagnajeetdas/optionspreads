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

task :clear_oldoptions => :environment do
  puts "Cleaning up the db..."
  	StockquoteDownloadJob.perform_later("clear_oldoptions")
  puts "done."
end
