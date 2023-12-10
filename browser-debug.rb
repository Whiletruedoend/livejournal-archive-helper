require 'open-uri'
require 'nokogiri'
require 'fileutils'

require 'watir'
require 'webdrivers'
require 'faker'
require 'selenium'

require 'json'
require "base64"

require 'logger'

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

platform_arch = ARCH.x64? ? "x86_64" : "i686"
platform = platform_version(platform_arch)

chrome_path = Dir["#{Dir.pwd}/_browsers/chrome-#{platform}/chrome*"].reject { |f| [".pak",".dll"].include?(File.extname(f)) || File.basename(f).include?("_") }[0]
chromedriver_path = Dir["#{Dir.pwd}/_browsers/chromedriver*"].reject { |f| File.extname(f) == ".zip" }[0]

# https://peter.sh/experiments/chromium-command-line-switches/
# 'print-to-pdf'
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

browser.goto "https://google.com"

sleep(999999999)