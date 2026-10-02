class PagesController < ApplicationController
  def index
  end

  def show
    @page = params[:page].to_s.strip

    if @page.blank?
      @error = "Masukkan path file"
      render :index
      return
    end

    case security_level
    when "low"
      handle_low(@page)
    when "medium"
      handle_medium(@page)
    when "high"
      handle_high(@page)
    end

    render :index
  end

  private

  # LEVEL LOW: Nggak ada proteksi sama sekali
  def handle_low(page)
    file_path = Rails.root.join(page)
    
    if File.exist?(file_path) && File.file?(file_path)
      @content = File.read(file_path)
      @filename = File.basename(file_path)
    else
      @error = "File not found: #{page}"
    end
  end

  # LEVEL MEDIUM: Blacklist "../" string mentah (nggak decode dulu)
  def handle_medium(page)
  # Cuma blacklist "../" string mentah doang
  if page.include?("../")
    @error = "Invalid path detected"
    return
  end

  # Decode URL-encoded character
  decoded_page = CGI.unescape(page)
  
  file_path = Rails.root.join(decoded_page)
  
  if File.exist?(file_path) && File.file?(file_path)
    @content = File.read(file_path)
    @filename = File.basename(file_path)
  else
    @error = "File not found: #{decoded_page}"
  end
end

  # LEVEL HIGH: Whitelist ketat + realpath validation
  def handle_high(page)
    # List file yang boleh dibaca
    allowed_files = [
      "app/views/pages/index.html.erb",
      "app/views/pages/about.html.erb",
      "README.md"
    ]

    # Cek apakah page ada di whitelist
    unless allowed_files.include?(page)
      @error = "Access denied: File not in whitelist"
      return
    end

    file_path = Rails.root.join(page)
    
    # Resolve ke realpath (anti-symlink bypass)
    begin
      real_path = File.realpath(file_path)
    rescue Errno::ENOENT
      @error = "File not found"
      return
    end

    # Double check: pastikan resolved path masih dalam project
    project_root = File.realpath(Rails.root)
    unless real_path.start_with?(project_root)
      @error = "Access denied: Path outside project"
      return
    end

    # Baca filenya
    if File.file?(real_path)
      @content = File.read(real_path)
      @filename = File.basename(real_path)
    else
      @error = "Not a file"
    end
  end
end
