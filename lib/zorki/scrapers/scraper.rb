# frozen_string_literal: true

# require_relative "user_scraper"
require "capybara/dsl"

Capybara.default_driver = :selenium_chrome
Capybara.app_host = "https://instagram.com"
Capybara.default_max_wait_time = 15

module Zorki
  class Scraper
    include Capybara::DSL

    private

    def login
      # Go to the home page
      visit("/")
      # Check if we're redirected to a login page, if we aren't we're already logged in
      return unless page.has_xpath?('//*[@id="loginForm"]/div/div[3]/button')

      fill_in("username", with: "cguess@gmail.com")
      fill_in("password", with: "PLGArwZ8QKNqXyG")
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
