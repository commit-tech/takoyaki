class HomeController < ApplicationController
	before_action :authenticate_user!
	def index

		if user_signed_in?
			@uu=current_user
			#redirect_to new_user_session_path
		else
			redirect_to new_user_session_path
		end

	end
end
