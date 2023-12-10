require 'open-uri'
require 'zip'
require "find"

require "./main"

def install()
  install_menu = <<~EOS
   ##################################### 
   #                                   #
   #                                   #
   #    ░█░█▄░█░▄▀▀░▀█▀▒▄▀▄░█▒░░█▒░    #
   #    ░█░█▒▀█▒▄██░▒█▒░█▀█▒█▄▄▒█▄▄    #
   #                                   #
   #                                   #
   #####################################
  EOS
  puts(install_menu)

  platform_arch = ARCH.x64? ? "x86_64" : "i686"
  platform = platform_version(platform_arch)
  print("\nDetected OS and ARCH: #{platform}")
    
  not_detected = <<~EOS
  \n\nPlatform not detected!
  Further installation is not possible.
  Please, execute instructions manually, or fix installation code if you think it's a bug.
  EOS
  return puts(not_detected) if platform == "unknown"
  mac_not_supported = <<~EOS
  \n\nMac platform not supported!
  Please, install the required packages manually and write the correct path in the main.rb file
  EOS
  return puts(mac_not_supported) if OS.mac?

  chome(platform)
  chromedriver(platform)
  ext_settings()

  done = <<~EOS
  \n\n##################################### 
  #                                   #   
  #                                   #
  #        ░█▀▄░▄▀▄░█▄░█▒██▀░█        #
  #        ▒█▄▀░▀▄▀░█▒▀█░█▄▄░▄        #
  #                                   #
  #                                   #
  #####################################
  EOS
  puts(done)
end

def chome(platform)
  print("\n\nChecking the installation of chrome...")
  chome_dir = "#{Dir.pwd}/_browsers/chrome-#{platform}"
  puts("\n  Chome path: #{chome_dir}")
    
  unless Dir.exist?(chome_dir)
    print("  Local chrome not found! Trying to download the stable version..")
    unless File.exist?("#{chome_dir}.zip")
      chrome_version = "116.0.5845.96" # Need to get the latest version from the site?
      download_url = "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/#{chrome_version}/#{platform}/chrome-#{platform}.zip"

      download = URI.open(download_url)
      IO.copy_stream(download, "#{chome_dir}.zip")

      print("\n  Downloading is complete..\n")
    end
    print("\n  Extracting chrome-#{platform}.zip...\n")
    Zip::File.open("#{chome_dir}.zip") do |zip|
      zip.each do |entry|
        entry_path=File.join("#{Dir.pwd}/_browsers", entry.name)
        FileUtils.mkdir_p(File.dirname(entry_path))
        zip.extract(entry, entry_path) unless File.exist?(entry_path)
      end
    end
    print("  Extracting complete!\n")
  else
    manifest = Dir["#{chome_dir}/*.manifest"][0]
    chrome_version = !manifest.nil? ? File.basename(manifest, ".manifest") : "unknown"
    print("  Local chrome was found! Version: #{chrome_version}")
  end

  # give execution right
  if OS.linux?
    print("  \nGive execution rights to chrome folder ...\n")
    res = `chmod +x #{chome_dir}/ -R`
    print(res)
    res = `ls -l #{chome_dir}/chrome`
    print(res)
  end
end

def chromedriver(platform)
  print("\n\nChecking the installation of chromedriver...")
  chromedriver_dir = "#{Dir.pwd}/_browsers"
  chromedriver = Dir["#{chromedriver_dir}/chromedriver*"].reject { |f| File.extname(f) == ".zip" }[0]
  unless chromedriver.nil?
    chromedriver_bin = File.basename(chromedriver)
    chromedriver_version = `#{chromedriver_dir}/#{chromedriver_bin} -version`
    chromedriver_version = chromedriver_version.match(/\d*\.\d*\d*\.\d*\d*\.\d*/)
    print("\n  Local chromedriver was found! Version: #{chromedriver_version}\n")
  else
    print("\n  Local chromedriver not found! Trying to download the stable version..\n")
    unless File.exist?("#{chromedriver_dir}/chromedriver-#{platform}.zip")
      chromedriver_version = "116.0.5845.96" # Need to get the latest version from the site?
      download_url = "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/#{chromedriver_version}/#{platform}/chromedriver-#{platform}.zip"
        
      download = URI.open(download_url)
      IO.copy_stream(download, "#{chromedriver_dir}/chromedriver-#{platform}.zip")

      print("  Downloading is complete..\n")
    end
    print("  Extracting chromedriver-#{platform}.zip...\n")
    Zip::File.open("#{chromedriver_dir}/chromedriver-#{platform}.zip") do |zip|
      zip.each do |entry|
        entry_path=File.join("#{Dir.pwd}/_browsers", entry.name.split('/').last)
        zip.extract(entry, entry_path) unless File.exist?(entry_path)
      end
    end
    print("  Extracting complete!\n")
    chromedriver = Dir["#{chromedriver_dir}/chromedriver*"].reject { |f| File.extname(f) == ".zip" }[0]
    chromedriver_bin = File.basename(chromedriver)
  end

  # give execution right
  if OS.linux?
    print("  \nGive execution rights to: ./chromedriver binary...\n")
    res = `chmod +x #{chromedriver_dir}/#{chromedriver_bin}`
    print(res)
    res = `ls -l #{chromedriver_dir}/#{chromedriver_bin}`
    print(res)
  end
end

# extension settings
def ext_settings
  print("\nChecking the installation of _ChromeData settings...")
  chromedata_path = "#{Dir.pwd}/_browsers/_ChromeData"
  puts("\n  _ChromeData path: #{chromedata_path}")

  unless Dir.exist?(chromedata_path)
    print("  _ChromeData folder not found! Trying to create folder...\n\n")
    FileUtils.mkdir_p(chromedata_path)
  else
    print("  _ChromeData folder was found!\n\n")
  end

  ext_settings_path = "#{chromedata_path}/Default/Local Extension Settings/"
  # Violentmonkey script
  tfile = "#{ext_settings_path}/jinjaccalgkegednnccohejagnlnfdag/000003.log"
  unless File.exist?(tfile)
    print("  Extension settings not found! Extracting _settings.zip...\n")
    Zip::File.open("#{Dir.pwd}/_browsers/_ext/_settings.zip") do |zip|
      zip.each do |entry|
        entry_path=File.join("#{Dir.pwd}/_browsers", entry.name)
        FileUtils.mkdir_p(File.dirname(entry_path))
        zip.extract(entry, entry_path){ true }
      end
    end
    print("  Extracting complete!\n")
  else
    print("  Extension settings was found!\n")
    # script presense check
    if (File.size(tfile) < 7000)
      print("  Incorrect Violentmonkey script size! Extracting _settings.zip...\n")
      Zip::File.open("#{Dir.pwd}/_browsers/_ext/_settings.zip") do |zip|
        zip.each do |entry|
          entry_path=File.join("#{Dir.pwd}/_browsers", entry.name)
          FileUtils.mkdir_p(File.dirname(entry_path))
          zip.extract(entry, entry_path){ true }
        end
      end
      print("  Extracting complete!\n")
    else
      print("  Correct Violentmonkey script size!")
    end
  end
end

if __FILE__ == $0
  install()
end