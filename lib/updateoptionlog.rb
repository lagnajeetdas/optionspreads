class Updateoptionlog
	require 'date'
	def initialize(function_name, activity, execution_time, count)

		@function_name = function_name
		@activity = activity
		@count = count.to_i

		update_db

	end


	def update_db

		odl = Optiondownloadlog.new(activity: @activity, function_name: @function_name, execution_time: DateTime.now(), count: @count)

		if odl.save
			#p "Updated successfully"
		else
			p "Could not save"
		end
	end



end