# frozen_string_literal: true

require "typhoeus"

module Zorki
  class PostScraper < Scraper
    def parse(id)
      # Stuff we need to get from the DOM (implemented is starred):
      # - User
      # - Text
      # - Image/Video
      # - Date
      # - Number of likes
      # - Hashtags

      login

      visit("/p/#{id}/")

      # We need to see if this is a single image post or a slideshow. We do that
      # by looking for a single image, if it's not there, we assume the alternative.
      images = []
      if page.has_xpath?('//*[@id="react-root"]/section/main/div/div[1]/article/div[2]/div/div/div[1]/img')
        srcset = find(:xpath, '//*[@id="react-root"]/section/main/div/div[1]/article/div[2]/div/div/div[1]/img')["srcset"]
        image_url = url_for_largest_resolution_from_srcset(srcset)
        images << Zorki.retrieve_image(image_url)
      else
        # If we have a slideshow here we'll loop, clicking the advance buttons as we go, until we hit the end.

        # The first image has this xpath
        image_xpath = '//*[@id="react-root"]/section/main/div/div[1]/article/div[2]/div/div[1]/div[2]/div/div/div/ul/li[2]/div/div/div/div[1]/img'
        loop do
          srcset = find(:xpath, image_xpath)['srcset']
          # Parse the srcset to get the largest version of the image
          image_url = url_for_largest_resolution_from_srcset(srcset)
          images << Zorki.retrieve_image(image_url)
          buttons = all(:xpath, '//*[@id="react-root"]/section/main/div/div[1]/article/div[2]/div/div[1]/div[2]/div/button')

          # From here on images have the following xpath (probably because the previous image is still in the DOM just offscreen)
          image_xpath = '//*[@id="react-root"]/section/main/div/div[1]/article/div[2]/div/div[1]/div[2]/div/div/div/ul/li[3]/div/div/div/div[1]/img'
          # Images count is one if we're on the first slide, so we'll click the only button we should find
          # We need to sleep after each one to give it time to catch up so we can get the new buttons
          if images.count == 1
            buttons[0].click
            sleep(10)
          elsif buttons.count > 1
            # If there's more than one button we want the second one, since that'll advance us
            buttons[1].click
            sleep(10)
          else
            # Otherwise, we're at the end, go with god.
            break
          end
        end
      end

      text = find(:xpath, '//*[@id="react-root"]/section/main/div/div[1]/article/div[3]/div[1]/ul/div/li/div/div/div[2]/span').text
      date = DateTime.parse(find(:xpath, '//*[@id="react-root"]/section/main/div/div[1]/article/div[3]/div[2]/a/time')["title"])
      number_of_likes = number_string_to_integer(find(:xpath, '//*[@id="react-root"]/section/main/div/div[1]/article/div[3]/section[2]/div/div/a/span').text)
      username = find(:xpath, '//*[@id="react-root"]/section/main/div/div[1]/article/header/div[2]/div[1]/div[1]/span/a').text

      # This has to run last since it switches pages
      user = User.lookup([username]).first

      {
        images: images,
        text: text,
        date: date,
        number_of_likes: number_of_likes,
        user: user,
        id: id
      }
    end

    private

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

    def url_for_largest_resolution_from_srcset(srcset)
      srcset.split(',').last.split(' ').first
    end
  end
end
