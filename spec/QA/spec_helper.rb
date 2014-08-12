require 'rspec'
require 'selenium-webdriver'

module SpecHelper
  class Driver
    attr_reader :driver
    BROWSERS = ['firefox', 'chrome', 'internet_explorer', 'opera']
    OSES     = ['XP', 'VISTA', 'LINUX', 'Mac 10.8']

    def initialize(title)
      @title = title
      @environment = ENV['ENVIRONMENT'] 
      raise "You need to specify an environment ex. 'ENVIRONMENT=delta ./test'" unless @environment
      @resolution = ENV['RESOLUTION']
      @browser = ENV['BROWSER'] || 'chrome'
      raise "BROWSER must be one of #{BROWSERS.join(', ')}" unless BROWSERS.include?(@browser.to_s)
      @version = ENV['VERSION'] || '13'
      @os      = ENV['OS'] || :XP
      raise "OS must be one of #{OSES.join(', ')}" unless OSES.include?(@os.to_s)

      @driver = if ENV['TEST_ENV'] == 'local'
                  local_driver
                else
                  saucelabs_driver
                end

        $driver = @driver
        $wait = Selenium::WebDriver::Wait.new(:timeout => 30)
        $long_wait = Selenium::WebDriver::Wait.new(:timeout => 90)
    end

    def local_driver
      Selenium::WebDriver.for(@browser.to_sym)
    end

    def goto(url)
      if @environment == 'TeleSignJSON'
        @driver.navigate.to "https://dl.dropboxusercontent.com/u/11775080/img_count_output.txt"
      else
        @driver.navigate.to "http://www.telesign.com"+url
      end
    end

    def hover(type, selector, options = {})
      # Get element to mouse over
      e = @driver.find_element(type, selector)
      # Use Javascript to mouseover
      @driver.execute_script("if(document.createEvent){var evObj = document.createEvent('MouseEvents');evObj.initEvent('mouseover', true, false); arguments[0].dispatchEvent(evObj);} else if(document.createEventObject) { arguments[0].fireEvent('onmouseover');}", e)
      # Do extra stuff given by the block
      yield e if block_given?
      begin
        # Mouse out using Javascript
        @driver.execute_script("if(document.createEvent){var evObj = document.createEvent('MouseEvents');evObj.initEvent('mouseout', true, false); arguments[0].dispatchEvent(evObj);} else if(document.createEventObject) { arguments[0].fireEvent('onmouseout');}", e)
      rescue
      end
    end
  end

  def find_element(*params)
    @driver.find_element(*params)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    false
  end

  def self.time
    Time.now.to_i.to_s
  end

  def self.get_time_in_milli(start, finish)
    puts (finish - start) * 1000.0
  end
end

RSpec.configure do |config|
  config.around(:each) do |example|
    @driver = SpecHelper::Driver.new((example.metadata[:example_group][:description_args] + example.metadata[:description_args]).join(' '))
    run_status = example.run
    success = !(run_status.is_a?(RSpec::Expectations::ExpectationNotMetError) || run_status.class.to_s =~ /Error/)
    bridge = @driver.driver.instance_variable_get(:@bridge)

    unless bridge.http.instance_variable_get(:@server_url).to_s.inspect =~ /127\.0\.0\.1/
      session_id = bridge.session_id
      command = %[curl -H "Content-Type:text/json" -s -X PUT -d '{"passed": #{success}}' http://cloudbees_bleacher:b3af4895-9684-4c75-8211-246d26fb7183@saucelabs.com/rest/v1/cloudbees_bleacher/jobs/#{session_id}]
      `#{command}`
    end
    @driver.quit
  end
end
