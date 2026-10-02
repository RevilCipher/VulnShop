class OrdersController < ApplicationController
  before_action :require_login

  def index
    @orders = Order.where(user_id: current_user.id)
  end

  def create
    product = Product.find(params[:product_id])
    qty = params[:quantity].to_i

    if security_level == "low"
      price = params[:price].to_f
    elsif security_level == "medium"
      price = params[:price].to_f
      qty = 1 if qty < 1
    else
      price = product.price
      qty = 1 if qty < 1
    end

    total = price * qty
    Order.create!(user: current_user, product: product, quantity: qty, total_price: total)
    current_user.update!(balance: current_user.balance - total)
    redirect_to orders_path, notice: "Order dibuat. Total: #{total}"
  end
end
