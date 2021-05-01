# frozen_string_literal: true

require "typhoeus"

module Zorki
  class UserScraper < Scraper
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

      profile_image_url = find(:xpath, '//*[@id="react-root"]/section/main/div/header/div/div/span/img')["src"]
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
  end
end
