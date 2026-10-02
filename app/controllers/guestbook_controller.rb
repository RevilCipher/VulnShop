class GuestbookController < ApplicationController
  def index
    @entries = Guestbook.order(created_at: :desc)
  end

  def create
    msg = params[:message]
    msg = ERB::Util.html_escape(msg) if security_level == "high"
    Guestbook.create!(name: params[:name], message: msg)
    redirect_to guestbook_path, notice: "Pesan ditambahkan"
  end
end
