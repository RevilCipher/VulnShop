class AdminController < ApplicationController
  def index
    redirect_to root_path, alert: "Khusus admin" unless admin?
    @users  = User.all
    @orders = Order.includes(:user, :product).order(created_at: :desc).limit(50)
  end
end
