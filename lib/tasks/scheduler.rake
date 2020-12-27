desc "This task is called by the Heroku scheduler add-on"
task :download_stocksuniverse => :environment do
  puts "Getting stocks from finnhub..."
  	StockquoteDownloadJob.perform_later
  puts "done."
end
