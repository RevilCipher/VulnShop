class SecurityController < ApplicationController
  def index; end

  def update
    session[:security_level] = params[:level]
    redirect_to security_path, notice: "Level: #{params[:level]}"
  end
end
