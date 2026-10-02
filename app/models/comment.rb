class Comment < ApplicationRecord
  belongs_to :product
  belongs_to :user, optional: true
  validates :content, presence: true
end
