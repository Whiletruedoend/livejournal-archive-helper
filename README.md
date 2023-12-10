# livejournal-archive-helper

## Description

The script is designed to help archive articles from the livejournal site. It parses all articles of a specified user, then automatically opens them in a browser and saves them in PDF format.

## Features:
  - Downloading articles by any user;
  - Moving comments to a single page and automatically expand them (script.js);
  - Clear downloading without ads and banners;
  - Potencial ability to download hidden articles (for friends only) (available only after logging in to your account) (theoretically, not tested);

## Requirements

 - OS: windows, linux (mac not supported sorry);
 - Ruby (3.1.4);

## Install

  * Install ruby (3.1.4):
    * (For Windows) you can use [RubyInstaller](https://rubyinstaller.org/downloads/);
    * For [rvm](https://rvm.io/):
    ```ssh
     rvm install ruby-3.1.4
    ```
    * For [rbenv](https://github.com/rbenv/rbenv):
    ```ssh
     rbenv install 3.1.4
    ```

  * Download repository:
   ```
   git clone https://github.com/Whiletruedoend/livejournal-archive-helper

   cd ./livejournal-archive-helper
   ```
  
  * Run bundler:
  ```
    bundle
  ```

  ## There are two ways to proceed with the installation:

  ### Automatic (recommended)

  * Run intall script:
  ```
    ruby install.rb
  ```

  ### Manual

  1. Download Chrome For Testing (chrome) and Chromedriver from link: https://googlechromelabs.github.io/chrome-for-testing/
  2. Extract `chrome archive` to: `./livejournal-archive-helper/_browsers`
  (The folder will contain the chrome (ex. chrome-win64) folder)
  3. From `chromedriver archive` extact `chromedriver` file to: `./livejournal-archive-helper/_browsers`
  (The folder will contain the chromedriver (ex. chromedriver.exe) file)
  4. Extract the contents of file `./livejournal-archive-helper/_browsers/_ext/_settings.zip` to: `./livejournal-archive-helper/_browsers`

## Run
 
  * Now you can run main script:
  ```
    ruby main.rb
  ```

## Advanced Chrome profile customize

If you need to customize your browser (install/change extensions or log in to your account), you need to do the following:

 ## Automatic way (recommended)

* Run debug script:
  ```
    ruby browser-debug.rb
  ```

## Manual way

* Go to chrome browser folder;
  * (For windows): Create shortcut .lnk and add:

    ```
    --user-data-dir="path\to\_browsers\_ChromeData"
    ```
    , where you need to change the path to your path where the _ChromeData folder is located.

  * (For linux): just run chrome with this param;
* Now you can run chrome and make your changes;

## Contribution

  1) Fork tis project;
  2) Make changes to the forked project;
  3) On the page of this repository, poke Pull Requests and make a Pull Request by selecting your fork in the right list; 
  
## Contact
If you have any ideas or your own developments, or just questions about the performance of the code, then you can always contact me at the following addresses: 

- [Matrix](https://matrix.to/#/@whiletruedoend:matrix.org)