# frozen_string_literal: true

require "capybara/dsl"
require "typhoeus"

Capybara.default_driver = :selenium_chrome
Capybara.app_host = "https://instagram.com"
Capybara.default_max_wait_time = 15

module Zorki
  module Scraper
    class UserScraper
      include Capybara::DSL

      def parse(username)
        # Stuff we need to get from the DOM (implemented is starred):
        # - *Name
        # - *Username
        # - *No. of posts
        # - *Verified
        # - *No. of followers
        # - *No. of people they follow
        # - *Profile
        #   - *description
        #   - *links
        # - *Profile image
        login
        visit("/#{username}/")

        # Get the username (to verify we're on the right page here)
        scraped_username = find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/div[1]/h2').text
        raise Zorki::Error unless username == scraped_username

        profile_image_url = find(:xpath, '//*[@id="react-root"]/section/main/div/header/div/div/span/img')["src"],
        to_return = {
          name: find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/div[2]/h1').text,
          username: username,
          number_of_posts: number_string_to_integer(find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/ul/li[1]/span/span').text),
          number_of_followers: number_string_to_integer(find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/ul/li[2]/a/span').text),
          number_of_following: number_string_to_integer(find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/ul/li[3]/a/span').text),
          verified: page.has_xpath?('//*[@id="react-root"]/section/main/div/header/section/div[1]/div[1]/span[@title="Verified"]'),
          title: find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/ul/li[3]/a/span').text,
          profile: find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/div[2]/span').text,
          profile_link: find(:xpath, '//*[@id="react-root"]/section/main/div/header/section/div[2]/a[1]').text,
          profile_image: fetch_image(profile_image_url)
        }

        to_return
      end

      private

      def login
        visit("/")
        fill_in("username", with: "cguess@gmail.com")
        fill_in("password", with: "PLGArwZ8QKNqXyG")
        click_on("Log In")
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
end
