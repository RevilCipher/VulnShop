class Product < ApplicationRecord
  has_many :comments, dependent: :destroy
  has_many :orders,   dependent: :destroy
end
