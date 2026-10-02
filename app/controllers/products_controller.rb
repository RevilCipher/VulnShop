class ProductsController < ApplicationController
  def index
    if params[:q].present?
      if security_level == "low"
        begin
          @products = Product.find_by_sql(
            "SELECT * FROM products WHERE name LIKE '%#{params[:q]}%'"
          )
        rescue ActiveRecord::StatementInvalid
          @products = Product.where("name LIKE ?", "%#{params[:q]}%")
        end
      else
        @products = Product.where("name LIKE ?", "%#{params[:q]}%")
      end
    else
      @products = Product.all
    end
  end

  def show
    @product = Product.find(params[:id])
    @comments = @product.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
  end
end
