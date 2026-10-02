require "open-uri"
require "uri"
require "yaml"
require "net/http"
require "base64"

class FetchController < ApplicationController
  def index
    @level = params[:level] || security_level
    @mode  = params[:mode].presence || "read"
    @url   = params[:url]

    if @url.present?
      case @level
      when "low"    then handle_low(@url, @mode)
      when "medium" then handle_medium(@url, @mode)
      when "high"   then handle_high(@url, @mode)
      else @content = "Level tidak dikenal: #{@level}"
      end
    end

    @content = safe_utf8(@content) if @content
  end

  private

  def safe_utf8(str)
    str.to_s.dup.force_encoding("UTF-8").scrub("?")
  end

  # ============================================================
  # ROUTER
  # ============================================================
  def handle_low(url, mode)
    case mode
    when "read"    then read_low(url)
    when "eval"    then eval_low(url)
    when "system"  then system_low(url)
    when "yaml"    then yaml_low(url)
    when "marshal" then marshal_low(url)
    when "ssrf"    then ssrf_low(url)
    when "gopher"  then gopher_low(url)
    else @content = "Mode tidak dikenal: #{mode}"
    end
  end

  def handle_medium(url, mode)
    case mode
    when "read"    then read_medium(url)
    when "eval"    then eval_medium(url)
    when "system"  then system_medium(url)
    when "yaml"    then yaml_medium(url)
    when "marshal" then marshal_medium(url)
    when "ssrf"    then ssrf_medium(url)
    when "gopher"  then gopher_medium(url)
    else @content = "Mode tidak dikenal: #{mode}"
    end
  end

  def handle_high(url, mode)
    case mode
    when "read"    then read_high(url)
    when "eval"    then eval_high(url)
    when "system"  then system_high(url)
    when "yaml"    then yaml_high(url)
    when "marshal" then marshal_high(url)
    when "ssrf"    then ssrf_high(url)
    when "gopher"  then gopher_high(url)
    else @content = "Mode tidak dikenal: #{mode}"
    end
  end

  # ============================================================
  # MODE: read
  # ============================================================
  def read_low(url)
    if url.start_with?("file://")
      @content = safe_utf8(File.read(url.sub("file://", "")))
    elsif url.start_with?("data:")
      @content = safe_utf8(decode_data(url))
    elsif url.start_with?("http://") || url.start_with?("https://")
      @content = safe_utf8(URI.open(url, open_timeout: 5).read)
    else
      @content = "❌ Protocol tidak didukung"
    end
  rescue => e
    @content = "Error: #{e.message}"
  end

  def read_medium(url)
    if url.include?("../") || url.include?("..\\")
      @content = "❌ Path traversal terdeteksi"
      return
    end
    if url.downcase.start_with?("file://")
      @content = "❌ file:// diblok di MEDIUM"
      return
    end
    read_low(url)
  end

  # HIGH: otomatis — cuma boleh baca file di dalam project
  def read_high(url)
    if url.start_with?("file://")
      path = url.sub("file://", "")

      # Resolve ke realpath
      begin
        real_path = File.realpath(path)
      rescue Errno::ENOENT
        @content = "❌ File tidak ditemukan: #{path}"
        return
      end

      # Cek apakah di dalam project
      project_root = File.realpath(Rails.root)
      unless real_path.start_with?(project_root)
        @content = "❌ File di luar project diblok: #{real_path}"
        return
      end

      # Cek apakah file (bukan direktori)
      unless File.file?(real_path)
        @content = "❌ Bukan file"
        return
      end

      @content = safe_utf8(File.read(real_path))
      return
    end

    # HTTP: cek domain otomatis
    if url.start_with?("http://") || url.start_with?("https://")
      uri = URI.parse(url) rescue nil
      unless uri && uri.host
        @content = "❌ URL tidak valid"
        return
      end

      # Blok IP internal otomatis
      if internal_host?(uri.host)
        @content = "❌ Host internal diblok: #{uri.host}"
        return
      end

      @content = safe_utf8(URI.open(url, open_timeout: 5).read)
      return
    end

    read_low(url)
  end

  # ============================================================
  # MODE: eval
  # ============================================================
  def eval_low(url)
    code = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read
    @content = safe_utf8(eval(code).to_s)
  rescue => e
    @content = "Error: #{e.message}"
  end

  def eval_medium(url)
    code = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read

    blacklist = ["system", "exec", "eval", "`", "IO.popen", "Open3", "spawn"]
    if blacklist.any? { |b| code.include?(b) }
      @content = "❌ Kode berbahaya diblok di MEDIUM"
      return
    end

    @content = safe_utf8(eval(code).to_s)
  rescue => e
    @content = "Error: #{e.message}"
  end

  # HIGH: otomatis — cuma boleh operasi "aman" (string, number, array, hash)
  def eval_high(url)
    code = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read

    # Cek otomatis: nggak boleh ada method call, backtick, atau konstanta berbahaya
    dangerous = [
      /`/,                    # backtick
      /\bsystem\b/,
      /\bexec\b/,
      /\beval\b/,
      /\bspawn\b/,
      /\bIO\b/,
      /\bFile\b/,
      /\bDir\b/,
      /\bKernel\b/,
      /\bProcess\b/,
      /::/,                   # konstanta
      /\.\w+\s*\(/            # method call
    ]

    if dangerous.any? { |p| code.match?(p) }
      @content = "❌ Kode berbahaya diblok di HIGH"
      return
    end

    @content = safe_utf8(eval(code).to_s)
  rescue => e
    @content = "Error: #{e.message}"
  end

  # ============================================================
  # MODE: system
  # ============================================================
  def system_low(url)
    @content = safe_utf8(`curl -s #{url}`)
  rescue => e
    @content = "Error: #{e.message}"
  end

  def system_medium(url)
    if url.match?(/[;&|`$()]/)
      @content = "❌ Karakter berbahaya diblok di MEDIUM"
      return
    end
    system_low(url)
  end

  # HIGH: otomatis — cuma boleh domain publik (bukan IP/internal)
  def system_high(url)
    # Extract host dari URL (kalau ada)
    host = url[/https?:\/\/([^\/\s;|&`$()]+)/, 1]

    if host.nil?
      @content = "❌ URL harus punya domain valid"
      return
    end

    # Ambil hostname tanpa port
    hostname = host.split(":").first

    # Blok otomatis kalau IP atau internal
    if internal_host?(hostname)
      @content = "❌ Host internal diblok: #{hostname}"
      return
    end

    system_low(url)
  end

  # ============================================================
  # MODE: yaml
  # ============================================================
  def yaml_low(url)
    data = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read
    @content = safe_utf8(YAML.load(data).inspect)
  rescue => e
    @content = "Error: #{e.message}"
  end

  def yaml_medium(url)
    data = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read
    if data.include?("!ruby/object")
      @content = "❌ Object deserialization diblok di MEDIUM"
      return
    end
    @content = safe_utf8(YAML.load(data).inspect)
  rescue => e
    @content = "Error: #{e.message}"
  end

  # HIGH: otomatis — cuma boleh tipe data primitif
  def yaml_high(url)
    data = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read

    # Cek otomatis: nggak boleh ada tag YAML (!) atau anchor (&) atau alias (*)
    if data.match?(/[!&*]/)
      @content = "❌ Tag/anchor/alias YAML diblok di HIGH"
      return
    end

    parsed = YAML.load(data)

    # Cek tipe hasil — cuma boleh Hash/Array/String/Number
    unless primitive?(parsed)
      @content = "❌ Tipe data tidak diizinkan di HIGH"
      return
    end

    @content = safe_utf8(parsed.inspect)
  rescue => e
    @content = "Error: #{e.message}"
  end

  # ============================================================
  # MODE: marshal
  # ============================================================
  def marshal_low(url)
    data = url.start_with?("data:") ? decode_data(url) : URI.open(url, open_timeout: 5).read
    @content = safe_utf8(Marshal.load(data).inspect)
  rescue => e
    @content = "Error: #{e.message}"
  end

  def marshal_medium(url)
    @content = "❌ Marshal diblok di MEDIUM"
  end

  def marshal_high(url)
    @content = "❌ Marshal diblok di HIGH"
  end

  # ============================================================
  # MODE: ssrf
  # ============================================================
  def ssrf_low(url)
    uri = URI.parse(url)
    res = Net::HTTP.get_response(uri)
    out = ["HTTP #{res.code} #{res.message}"]
    res.each_header { |k, v| out << "#{k}: #{v}" }
    out << ""
    out << res.body.to_s[0, 2000]
    @content = safe_utf8(out.join("\n"))
  rescue => e
    @content = "Error: #{e.message}"
  end

  def ssrf_medium(url)
    blocked = ["localhost", "127.0.0.1", "169.254.169.254", "0.0.0.0"]
    if blocked.any? { |b| url.include?(b) }
      @content = "❌ Internal host diblok di MEDIUM"
      return
    end
    ssrf_low(url)
  end

  # HIGH: otomatis — blok IP internal, cloud metadata, port DB
  def ssrf_high(url)
    uri = URI.parse(url) rescue nil
    unless uri && uri.host
      @content = "❌ URL tidak valid"
      return
    end

    # Blok otomatis
    if internal_host?(uri.host)
      @content = "❌ Host internal diblok: #{uri.host}"
      return
    end

    blocked_ports = [6379, 5432, 3306, 27017, 9200, 11211]
    if blocked_ports.include?(uri.port)
      @content = "❌ Port #{uri.port} diblok"
      return
    end

    ssrf_low(url)
  end

  # ============================================================
  # MODE: gopher
  # ============================================================
  def gopher_low(url)
    @content = safe_utf8(URI.open(url, open_timeout: 5).read)
  rescue => e
    @content = "Error: #{e.message}"
  end

  def gopher_medium(url)
    @content = "❌ gopher diblok di MEDIUM"
  end

  def gopher_high(url)
    @content = "❌ gopher diblok di HIGH"
  end

  # ============================================================
  # HELPER OTOMATIS
  # ============================================================
  def decode_data(url)
    if url.include?("base64,")
      data = url.split("base64,")[1]
      begin
        Base64.decode64(data)
      rescue
        "Invalid base64"
      end
    else
      url.sub(/^data:[^,]*,/, "")
    end
  end

  # Cek otomatis apakah host itu internal/IP privat
  def internal_host?(host)
    h = host.to_s.downcase

    # Localhost
    return true if ["localhost", "127.0.0.1", "::1", "0.0.0.0"].include?(h)

    # Cloud metadata
    return true if ["169.254.169.254", "metadata.google.internal"].include?(h)

    # IP privat
    if h.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
      ip = h.split(".").map(&:to_i)
      return true if ip[0] == 10
      return true if ip[0] == 172 && ip[1] >= 16 && ip[1] <= 31
      return true if ip[0] == 192 && ip[1] == 168
      return true if ip[0] == 127
      return true if ip[0] == 169 && ip[1] == 254
    end

    # IP desimal (2130706433 = 127.0.0.1)
    if h.match?(/\A\d+\z/)
      n = h.to_i
      return true if n >= 0 && n <= 0xFFFFFFFF
    end

    # IPv6
    return true if h.start_with?("[") || h.include?(":")

    false
  end

  # Cek otomatis apakah hasil parse cuma tipe primitif
  def primitive?(obj)
    case obj
    when String, Numeric, TrueClass, FalseClass, NilClass
      true
    when Array
      obj.all? { |x| primitive?(x) }
    when Hash
      obj.all? { |k, v| primitive?(k) && primitive?(v) }
    else
      false
    end
  end
end
