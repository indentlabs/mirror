class KoalaIntialize

  def self.get_posts(access_token)
  	@graph = Koala::Facebook::API.new("#{access_token}")
		@posts = @graph.get_connections("me", "posts", :limit => 10)
  end

end