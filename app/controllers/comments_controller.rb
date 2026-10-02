class CommentsController < ApplicationController
  def create
    @product = Product.find(params[:product_id])
    content = params[:comment][:content]

    if security_level == "high"
      content = ERB::Util.html_escape(content)
    elsif security_level == "medium"
      content = content.gsub(/<script.*?<\/script>/m, "")
    end

    # Buat comment dengan atau tanpa user (optional)
    @product.comments.create!(user: current_user, content: content)
    redirect_to product_path(@product), notice: "Komentar terkirim"
  end

  def destroy
    Comment.find(params[:id]).destroy
    redirect_back fallback_location: root_path, notice: "Komentar dihapus"
  end
end
