class RedirectController < ApplicationController
  def go
    url = params[:url] || "/"
    if security_level == "high"
      url = "/" unless url.start_with?("/")
    end
    redirect_to url, allow_other_host: true
  end
end
