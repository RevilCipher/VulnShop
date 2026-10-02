class CsrfController < ApplicationController
  skip_before_action :verify_authenticity_token, if: -> { security_level == "low" }

  def index
    @balance = current_user&.balance || 0
  end

  def transfer
    return redirect_to login_path unless current_user
    amount = params[:amount].to_i
    current_user.update!(balance: current_user.balance - amount)
    redirect_to csrf_lab_path, notice: "Transfer Rp #{amount} berhasil"
  end
end
