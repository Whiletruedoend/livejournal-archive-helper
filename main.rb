require 'open-uri'
require 'nokogiri'
require 'fileutils'

require 'watir'
require 'webdrivers'
require 'faker'
require 'selenium'

require 'logger'
require 'optparse'

Zip.warn_invalid_date = false

log_file = DateTime.now.strftime("%Y-%m-%d_%H_%M_%S")
Dir.mkdir("_logs") unless File.exists?("_logs")
LOG = Logger.new File.open("_logs/#{log_file}.log", 'w')
LOG.level = Logger::INFO

# increase time range (in seconds) if your pdf looks partial
WAITING_BEFORE_PRINT = 6.0..14.5
WAITING_AFTER_PRINT = 2.0..4.0

def main(options)
  author = options[:author]
  server_url = options[:server]
  yaml_load = options[:load]

  platform_arch = ARCH.x64? ? "x86_64" : "i686"
  platform = platform_version(platform_arch)

  # Alternative chrome variant: https://ungoogled-software.github.io/ungoogled-chromium-binaries/ (Manual install only)
  # ADVANCED USERS ONLY. DON'T TOUCH THIS If YOU WANT THE INSALLATION SCRIPT TO WORK.
  chrome_path = Dir["#{Dir.pwd}/_browsers/chrome-#{platform}/chrome*"].reject { |f| [".pak",".dll"].include?(File.extname(f)) || File.basename(f).include?("_") }[0]
  chromedriver_path = Dir["#{Dir.pwd}/_browsers/chromedriver*"].reject { |f| File.extname(f) == ".zip" }[0]
  
  print("\nDetected paths:\n")
  print("#{chrome_path}\n")
  print("#{chromedriver_path}\n")

  if !yaml_load.nil?
    if File.exists?(yaml_load)
      author_yaml = YAML.load_file(yaml_load) # Direct download from YAML
    else
      LOG.error("\nError! Not found YAML file from path:\n#{yaml_load}\n\n")
      print("\nError! Not found YAML file from path:\n#{yaml_load}\n\n")
      exit(0)
    end
  else
    author_yaml = parse_posts(server_url, author)
  end
  browser = browser_setting_up(author, chrome_path, chromedriver_path)

  author_yaml.each do |year, months|
    months.each do |month, posts|
      save_posts(browser, server_url, author, posts, year, month) unless posts.nil?
    end
  end
end

def browser_setting_up(author, chrome_path, chromedriver_path)
  LOG.info("Setting up browser settings...")
  print("\nSetting up browser settings...\n")
  # http://watir.com/guides/downloads/
  args = ["user-data-dir=#{Dir.pwd}/_browsers/_ChromeData", 'kiosk-printing', 'disable-background-timer-throttling', 'disable-crash-reporter', 'disable-component-update', 'enable-print-browser', ]

  options = Selenium::WebDriver::Chrome::Options.new.tap do |o|
    args.each do |arg|
      o.add_argument("--#{arg}")   
    end
    o.add_preference(:download, directory_upgrade: true, 
                                prompt_for_download: false)
    o.add_preference(:profile, "default_content_setting_values.automatic_downloads": 1)

    o.add_preference(:safebrowsing, enabled: true)
    
    o.add_preference(:excludeSwitches, ["enable-automation"])
    o.add_preference(:useAutomationExtension, false)

    o.add_extension("#{Dir.pwd}/_browsers/_ext/ublock_origin_1_54_0_0.crx")
    o.add_extension("#{Dir.pwd}/_browsers/_ext/umatrix_1_4_4_0.crx")
    o.add_extension("#{Dir.pwd}/_browsers/_ext/Violentmonkey.crx")
  end   

  Selenium::WebDriver::Chrome.path = chrome_path
  Selenium::WebDriver::Chrome::Service.driver_path = chromedriver_path

  browser = Watir::Browser.new :chrome, options: options
  LOG.info("Setting up browser settings... Done!")
  print("\nSetting up browser settings... Done!\n")
  return browser
end

def parse_calendar(server_url, author)
  LOG.info("Parsing #{author} years calendar...")
  print("\nParsing #{author} years calendar...")

  author_yaml_path = "#{author}/#{author}.yaml"
  FileUtils.mkdir_p("#{author}") unless Dir.exist?("#{author}")
  File.new(author_yaml_path, 'a+') if !File.exist?(author_yaml_path)
  author_yaml = YAML.load_file( author_yaml_path ) || {}

  html = URI.open("https://#{author}.#{server_url}/calendar")
  doc = Nokogiri::HTML(html)

  regex = /https:\/\/#{author}.#{server_url}\/(\d{4})/ 
  links = doc.css("li a").map { |l| l['href'] }.compact!
  years = links.map { |l| l.match?(regex) ? l.match(regex)[1].to_i : 0}.reject{ |y| y.zero? || y > 2038 || y < 1900 }.uniq
  years = [DateTime.now.year] if years.empty?
  years.append(DateTime.now.year) if years[DateTime.now.year].nil?
  years = years.sort

  new_years = years - author_yaml.keys
  last_posts = author_yaml.select{ |y| !author_yaml[y].select{ |m| (author_yaml[y][m]&.is_a?(Array))}.empty? }&.values&.last&.values&.select{ |v| !v.nil? }&.last || nil
  last_active_month = last_posts.nil? ? last_posts : author_yaml.values.select{|m| m.key(last_posts)}.last.key(last_posts)
  last_active_year = last_posts.nil? ? last_posts : author_yaml.select{ |y,m| m.key(last_posts) }.keys.last

  additional_params = { new_years: new_years, last_posts: last_posts, last_active_month: last_active_month, last_active_year: last_active_year}
  LOG.info("Additional params: #{additional_params}")

  years.each do |y|
    if author_yaml.has_key?(y)
      (1..12).each { |m| author_yaml[y].merge!({"#{sprintf('%.2d', m)}"=>nil}) unless author_yaml[y].has_key?(sprintf('%.2d', m)) }
    else
      month = {}
      (1..12).each{ |m| month.merge!("#{sprintf('%.2d', m)}"=>nil) }
      author_yaml.merge!(y=>month)
    end
  end

  File.open(author_yaml_path, 'w') { |f| YAML.dump(author_yaml, f) }
  LOG.info("Parsing #{author} years calendar... Done!")
  print("\nParsing #{author} years calendar... Done!\n")
  return years, additional_params
end

def parse_posts(server_url, author)
  years, additional_params = parse_calendar(server_url, author)
  LOG.info("Parsing #{author} post ids by years...")
  print("\nParsing #{author} post ids by years...")

  author_yaml_path = "#{author}/#{author}.yaml"
  author_yaml = YAML.load_file( author_yaml_path ) || {}
#  years = [2020,2021,2022,2023] # Uncomment if you want specify years manually.

  last_active_year = additional_params[:last_active_year]
  unless additional_params[:last_posts].nil?
    years = years.reject { |y| y < last_active_year }
    last_active_month = additional_params[:last_active_month]
    new_months = (last_active_month == "12") ? [last_active_month] : (last_active_month.to_i..12).map{ |m| sprintf('%.2d', m) }
  end

  years.each do |y|
    if last_active_year == y
      months = new_months
    else
      months = (1..12).map{ |m| sprintf('%.2d', m) }
    end
    months.each do |m|
      m_html = URI.open("https://#{author}.#{server_url}/#{y}/#{m}/")
      m_doc = Nokogiri::HTML(m_html)

      m_links = m_doc.css("dl a").map { |l| l['href'] }.compact
      m_regex = /https:\/\/#{author}.#{server_url}\/(\d{1,}).html(?<!thread)$/

      post_ids = m_links.map{ |l| l.match?(m_regex) ? l.match(m_regex)[1].to_i : 0 }.reject{ |p| p.zero?}.uniq
      author_yaml[y].merge!(m=>post_ids) unless post_ids.empty?
    end
  end

  File.open(author_yaml_path, 'w') { |f| YAML.dump(author_yaml, f) }
  LOG.info("Years: #{years}\nParsing #{author} post ids by years... Done!")
  print("\nYears: #{years}\nParsing #{author} post ids by years... Done!\n")
  return author_yaml
end

def save_posts(browser, server_url, author, posts, y, m)
  posts_path = "#{author}/#{y}/#{m}"

  posts.each_with_index  do |post_id, index|
    post_id = post_id.to_s

    next if File.directory?(posts_path) && (Date.today.year != y) && (sprintf('%.2d', Date.today.month) != m)

    begin
      url = "https://#{author}.#{server_url}/#{post_id}.html"

      browser.goto url
      sleep(rand(WAITING_BEFORE_PRINT))
      base64encodedContent = browser.driver.print_page(orientation: 'portrait')
      
      pdf_name = browser.title.gsub(/[\\*\/\\\\!\\|:?<>"]/, '').split(' ').join(' ')
      pdf_path = "#{Dir.pwd}/#{author}/#{pdf_name}.pdf"
      if OS.windows? && (pdf_path.length >= 260)
        pdf_path = pdf_path[0...259]
        print("Warning! The destination file path is too long! It has been shortened to 259 characters.\n")
      end
      File.open(pdf_path, 'wb') {|f| f.write(Base64.decode64(base64encodedContent)) }
      sleep(rand(WAITING_AFTER_PRINT))

    rescue Exception => e
      print("Error: #{e.message}\n")
      LOG.error("Error: #{e.message}\n")
      print("Try to retry after 5 seconds..")
      sleep(5)
      retry
    end
  end
  files = Dir.glob("#{author}/*").reject { |file| file.end_with?(".yaml") || File.directory?(file) }
  FileUtils.mkdir_p(posts_path)
  FileUtils.mv(files, posts_path) unless files.count.zero?
end

#### UTILS ####

def platform_version(platform_arch)
  if OS.windows?
    ARCH.x64? ? "win64" : "win32"
  elsif OS.mac?
    ARCH.x64? ? "mac-x64" : "mac-arm64"
  elsif OS.linux? || OS.unix? # unix?
    ARCH.x64? ? "linux64" : "unknown" # x32 not supported
  else
    "unknown"
  end
end

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end
  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end
  def OS.unix?
    !OS.windows?
  end
  def OS.linux?
    OS.unix? and not OS.mac?
  end
end

module ARCH
  def ARCH.x64?
    RUBY_PLATFORM.include?("x64") || RUBY_PLATFORM.include?("x86_64")
  end
#  def x32?
#    !RUBY_PLATFORM.include?("x64")
#  end
end

#### RUN MAIN ####
if __FILE__ == $0
  options = {}
  ARGV << '-h' if ARGV.empty?
  
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby main.rb [options]"

    opts.on("-a", "--author AUTHOR", "Specify LiveJournal author (required)") do |a|
      options[:author] = a
    end
    opts.on("-l", "--load [file path]", "Direct load from YAML file without parse (optional)") do |a|
      options[:load] = a
    end
    opts.on("-s", "--server [name]", "Specify LiveJournal server name (Default: livejournal.com)") do |s|
      options[:server] = s
    end
    opts.on_tail("-h", "--help", "Show this message") do
      print(opts)
      exit
    end
  end.parse!
  raise OptionParser::MissingArgument.new("-a") if options[:author].nil?

  options.merge!(:server=>'livejournal.com') if options[:server].nil?
  main(options)
end