# frozen_string_literal: true

# require_relative "user_scraper"
require "capybara/dsl"
require "dotenv/load"
require "oj"
require "selenium-webdriver"

Capybara.register_driver :chrome do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 10  # Don't wait 60 seconds to return Net::ReadTimeoutError. We'll retry through Hypatia after 10 seconds
  Capybara::Selenium::Driver.new(app, browser: :chrome, http_client: client)
end

Capybara.default_driver = :selenium_chrome
Capybara.default_max_wait_time = 15
Capybara.threadsafe = true
Capybara.reuse_server = true
Capybara.app_host = "https://instagram.com"

module Zorki
  class Scraper
    include Capybara::DSL

    def initialize
      Capybara.default_driver = :selenium_chrome
      Capybara.app_host = "https://instagram.com"
    end

    # Instagram uses GraphQL (like most of Facebook I think), and returns an object that actually
    # is used to seed the page. We can just parse this for most things.
    #
    # @returns Hash a ruby hash of the JSON data
    def find_graphql_script
      scripts = all("script", visible: false)
      # We search for a quoted term to find a JSON string that uses "graphql" as a key
      # graphql_script = scripts.find { |s| s.text(:all).include?('"graphql"') }
      # Let's look around if you can't find it in the previous line
      graphql_script = scripts.find { |s| s.text(:all).include?("items") }
      graphql_script = scripts.find { |s| s.text(:all).include?("graphql") } if graphql_script.nil?

      graphql_text = graphql_script.text(:all)

      # Clean up the javascript so we have pure JSON
      # We do this by scanning until we get to the first `{`, taking the subindex, then doing the
      # same backwards to find `}`
      index = graphql_text.index("{")
      graphql_text = graphql_text[index...]
      graphql_text = graphql_text.reverse
      index = graphql_text.index("}")
      graphql_text = graphql_text[index..] # this is not inclusive on purpose
      graphql_text = graphql_text.reverse
      Oj.load(graphql_text)
    end

  private

    def login
      # Go to the home page
      visit("https://instagram.com")
      # Check if we're redirected to a login page, if we aren't we're already logged in
      return unless page.has_xpath?('//*[@id="loginForm"]/div/div[3]/button')

      loop_count = 0
      while loop_count < 5 do
        fill_in("username", with: ENV["INSTAGRAM_USER_NAME"])
        fill_in("password", with: ENV["INSTAGRAM_PASSWORD"])
        click_on("Log In")

        break unless has_css?('p[data-testid="login-error-message"')
        loop_count += 1
        logger.debug("Error logging into Instagram, trying again")
        sleep(10)
      end

      # Sometimes Instagram just... doesn't let you log in
      raise "Instagram not accessible" if loop_count == 5

      # No we don't want to save our login credentials
      click_on("Not Now")
    end

    def fetch_image(url)
      request = Typhoeus::Request.new(url, followlocation: true)
      request.on_complete do |response|
        if request.success?
          return request.body
        elsif request.timed_out?
          raise Zorki::Error("Fetching image at #{url} timed out")
        else
          raise Zorki::Error("Fetching image at #{url} returned non-successful HTTP server response #{request.code}")
        end
      end
    end

    # Convert a string to an integer
    def number_string_to_integer(number_string)
      # First we have to remove any commas in the number or else it all breaks
      number_string = number_string.delete(",")
      # Is the last digit not a number? If so, we're going to have to multiply it by some multiplier
      should_expand = /[0-9]/.match(number_string[-1, 1]).nil?

      # Get the last index and remove the letter at the end if we should expand
      last_index = should_expand ? number_string.length - 1 : number_string.length
      number = number_string[0, last_index].to_f
      multiplier = 1
      # Determine the multiplier depending on the letter indicated
      case number_string[-1, 1]
      when "m"
        multiplier = 1_000_000
      end

      # Multiply everything and insure we get an integer back
      (number * multiplier).to_i
    end
  end
end

require_relative "post_scraper"
require_relative "user_scraper"
