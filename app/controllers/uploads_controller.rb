class UploadsController < ApplicationController
  def index
    @files = Dir.glob(Rails.root.join("public/uploads/*")).map { |f| File.basename(f) }
  end

  def create
    file = params[:file]
    return redirect_to upload_path, alert: "Pilih file" unless file

    if security_level == "high"
      allowed = %w[image/png image/jpeg image/gif]
      return redirect_to upload_path, alert: "Hanya image!" unless allowed.include?(file.content_type)
      name = "#{SecureRandom.hex(8)}#{File.extname(file.original_filename)}"
    else
      name = file.original_filename
    end

    File.open(Rails.root.join("public/uploads", name), "wb") { |f| f.write(file.read) }
    redirect_to upload_path, notice: "Upload sukses: #{name}"
  end
end
