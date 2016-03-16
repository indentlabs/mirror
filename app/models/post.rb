class Post < ActiveRecord::Base
  belongs_to :user
  # validates :post_id, uniqueness: true
end
