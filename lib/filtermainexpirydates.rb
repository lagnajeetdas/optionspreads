class Filtermainexpirydates



	def initialize(e_dates)
		@e_dates = e_dates
		@e_dates_new = Array []
		#filldates
		filter_main_expiry_dates
	end

	def filter_main_expiry_dates
		current_year = Time.new.year
		expirycalendars = Expirycalendar.distinct.pluck(:expiry_date)


		@e_dates.each do |e|

			p e.to_s
			if expirycalendars.include? e.to_s

				@e_dates_new.push(e.to_s)
				p "Added " + e.to_s
			end
		end

	end

	def new_exp_dates
		if !@e_dates_new.empty?
			@e_dates_new
		else @e_dates
			@e_dates
		end
	end


	def filldates
		expiry_dates_insert = ["2021-01-15","2021-02-19","2021-03-19","2021-04-16","2021-05-21","2021-06-18","2021-07-16","2021-08-20","2021-09-17","2021-10-15","2021-11-19","2021-12-17"]
		expiry_dates_insert = []
		expiry_dates_insert.each do |f|
			@ec = Expirycalendar.new(year: "2021", expiry_date: f.to_s)
			if @ec.save
				p "Saved " + f.to_s
			else
				p "Error saving"
			end
		end

		expiry_dates_insert = ["2022-01-21","2022-02-18","2022-03-18","2022-04-14","2022-05-20","2022-06-17","2022-07-15","2022-08-19","2022-09-16","2022-10-21","2022-11-18","2022-12-16"]
		
		expiry_dates_insert.each do |f|
			@ec = Expirycalendar.new(year: "2022", expiry_date: f.to_s)
			if @ec.save
				p "Saved " + f.to_s
			else
				p "Error saving"
			end
		end

	end



end