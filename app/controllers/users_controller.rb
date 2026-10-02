class UsersController < ApplicationController
  before_action :require_login, only: [:me]

  def index
    @users = User.all
  end

  def me
    redirect_to profile_path(current_user.id)
  end

  def show
    if security_level == "high" && current_user && current_user.id.to_s != params[:id] && current_user.role != "admin"
      redirect_to root_path, alert: "Akses ditolak"
    else
      @user = User.find_by(id: params[:id])

      unless @user
        redirect_to root_path, alert: "User tidak ditemukan"
        return
      end

      @orders = Order.where(user_id: @user.id)
    end
  end
end
