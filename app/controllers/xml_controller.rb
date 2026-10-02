require "nokogiri"

class XmlController < ApplicationController
  def index; end

  def parse
    xml = params[:xml].to_s
    if security_level == "low"
      doc = Nokogiri::XML(xml) { |c| c.noent }
      @result = doc.to_s
    else
      doc = Nokogiri::XML(xml)
      @result = doc.to_s
    end
    render :index
  end
end
