class User < ActiveRecord::Base
  include HTTParty
  # URL = "http://www.retort.us/bigram/parse" 
  devise :database_authenticatable, :registerable, :confirmable,
    :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_one :identity, :dependent => :destroy
  has_many :posts

  # validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update

  def self.find_for_oauth(auth, signed_in_resource = nil)
    identity = Identity.find_for_oauth(auth)
   	user = signed_in_resource ? signed_in_resource : identity.user
    if user.nil?
			email_is_verified = auth.info.email && (auth.info.verified || auth.info.verified_email)
      email = auth.info.email if email_is_verified
      user = User.where(:email => email).first if email
      if user.nil?
        user = User.new(
          user_name: auth.extra.raw_info.name,
          email: email ? email : auth.extra.raw_info.email,
          password: Devise.friendly_token[0,20]
        )
        user.skip_confirmation!
        user.save!
      end
    end
    if identity.user != user
      identity.user = user
      identity.access_token = auth.credentials.token
      identity.save!
    end
    user
  end

  def email_verified?
    self.email && self.email 
  end

  def self.send_post(message,user_name)
		response = HTTParty.get('http://www.retort.us/bigram/parse?message='+"#{message}"+ '&identifier='+"#{user_name}"+'&medium=Facebook')
  end

  def self.find_post(current_user)
  	@graph = Koala::Facebook::API.new("#{current_user.identity.access_token}")
		@posts = @graph.get_connections("me", "posts", :limit => 10)
		@posts.each do |post|
			unless Post.find_by_post_id(post["id"]).present?
				user_post = current_user.posts.new(:post_id => post["id"], :message => post["message"])
				if user_post.save
					User.send_post(user_post.message,current_user.user_name)
				end
			end
		end
		# User.delay(run_at: Time.current + 2.minute).find_post(current_user)
  	User.delay(run_at: (2).minutes.from_now).find_post(current_user)
  end
end
