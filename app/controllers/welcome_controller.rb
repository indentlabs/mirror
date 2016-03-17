class WelcomeController < ApplicationController
	require 'koala_intialize'
	def login
	end

	def thank_you
		@posts = KoalaIntialize.get_posts(current_user.identity.access_token)
		@posts.each do |post|
			unless Post.find_by_post_id(post["id"]).present?
				if post["message"].present?
					user_post = current_user.posts.new(:post_id => post["id"], :message => post["message"])
					if user_post.save
						User.send_post(user_post.message,current_user.user_name)
					end
				end
			end
		end
		User.delay(run_at: (2).minutes.from_now).find_post(current_user)
	end
end
