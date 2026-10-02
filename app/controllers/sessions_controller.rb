class SessionsController < ApplicationController
  def new; end

  def create
    if security_level == "low"
      user = User.find_by_sql(
        "SELECT * FROM users WHERE username = '#{params[:username]}' AND password = '#{params[:password]}' LIMIT 1"
      ).first
    elsif security_level == "medium"
      u = params[:username].gsub(/['"\\-]/, "")
      p = params[:password].gsub(/['"\\-]/, "")
      user = User.find_by_sql(
        "SELECT * FROM users WHERE username = '#{u}' AND password = '#{p}' LIMIT 1"
      ).first
    else
      user = User.find_by(username: params[:username], password: params[:password])
    end

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Login sukses sebagai #{user.username}"
    else
      flash[:alert] = "Login gagal"
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logout"
  end
end
