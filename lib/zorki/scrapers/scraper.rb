# frozen_string_literal: true

# require_relative "user_scraper"
require "capybara/dsl"
require "dotenv/load"
require "oj"

Capybara.default_driver = :selenium_chrome
Capybara.app_host = "https://instagram.com"
Capybara.default_max_wait_time = 15

module Zorki
  class Scraper
    include Capybara::DSL

    # Instagram uses GraphQL (like most of Facebook I think), and returns an object that actually
    # is used to seed the page. We can just parse this for most things.
    #
    # @returns Hash a ruby hash of the JSON data
    def find_graphql_script
      scripts = all("script", visible: false)
      graphql_script = scripts.find { |s| s.text(:all).include?("graphql") }
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
      visit("/")
      # Check if we're redirected to a login page, if we aren't we're already logged in
      return unless page.has_xpath?('//*[@id="loginForm"]/div/div[3]/button')

      fill_in("username", with: ENV["INSTAGRAM_USER_NAME"])
      fill_in("password", with: ENV["INSTAGRAM_PASSWORD"])
      click_on("Log In")

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
      number_string = number_string.gsub(",", "")
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
