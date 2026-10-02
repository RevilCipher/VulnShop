# app/models/user.rb
class User < ApplicationRecord
  has_many :comments
  has_many :orders
end

