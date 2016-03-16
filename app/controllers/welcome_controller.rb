class WelcomeController < ApplicationController
	def login
	end

	def thank_you
		@graph = Koala::Facebook::API.new("#{current_user.identity.access_token}")
		@posts = @graph.get_connections("me", "posts", :limit => 10)
		User.find_post(current_user)
		@posts.each do |post|
			unless Post.find_by_post_id(post["id"]).present?
				user_post = current_user.posts.new(:post_id => post["id"], :message => post["message"])
				if user_post.save
					User.send_post(user_post.message,current_user.user_name)
				end
			end
		end
		User.delay(run_at: (2).minutes.from_now).find_post(current_user)
	end
end
