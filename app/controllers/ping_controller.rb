class PingController < ApplicationController
  def index; end

  def run
    ip = params[:ip]
    if security_level == "low"
      @output = `ping -c 1 #{ip}`
    elsif security_level == "medium"
      ip = ip.gsub(/[;&|`$]/, "")
      @output = `ping -c 1 #{ip}`
    else
      require "ipaddr"
      begin
        IPAddr.new(ip)
        @output = `ping -c 1 #{ip}`
      rescue
        return redirect_to ping_path, alert: "IP tidak valid"
      end
    end
    render :index
  end
end
