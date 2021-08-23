# frozen_string_literal: true

require "typhoeus"

module Zorki
  class PostScraper < Scraper
    def parse(id)
      # Stuff we need to get from the DOM (implemented is starred):
      # - User *
      # - Text *
      # - Image * / Images * / Video *
      # - Date *
      # - Number of likes *
      # - Hashtags

      login

      visit("/p/#{id}/")
      graphql_object = find_graphql_script

      # We need to see if this is a single image post or a slideshow. We do that
      # by looking for a single image, if it's not there, we assume the alternative.
      if graphql_object["graphql"]["shortcode_media"]["is_video"] == false
        # Check if there is a slideshow or not
        if graphql_object["graphql"]["shortcode_media"]["edge_sidecar_to_children"].nil?
          # Single image
          image_url = graphql_object["graphql"]["shortcode_media"]["display_url"]
          images = [Zorki.retrieve_media(image_url)]
        else
          # Slideshow
          images = graphql_object["graphql"]["shortcode_media"]["edge_sidecar_to_children"]["edges"].map do |edge|
            Zorki.retrieve_media(edge["node"]["display_url"])
          end
        end
      else
        # some of these I've seen in both ways, thus the commented out lines
        # video_url = graphql_object["entry_data"]["PostPage"].first["graphql"]["shortcode_media"]["video_url"]
        video_url = graphql_object["graphql"]["shortcode_media"]["video_url"]
        video = Zorki.retrieve_media(video_url)
        # video_preview_image_url = graphql_object["entry_data"]["PostPage"].first["graphql"]["shortcode_media"]["display_resources"].last["src"]
        video_preview_image_url = graphql_object["graphql"]["shortcode_media"]["display_url"]
        video_preview_image = Zorki.retrieve_media(video_preview_image_url)
      end

      text = graphql_object["graphql"]["shortcode_media"]["edge_media_to_caption"]["edges"].first["node"]["text"]
      date = DateTime.strptime("#{graphql_object["graphql"]["shortcode_media"]["taken_at_timestamp"]}", "%s")
      number_of_likes = graphql_object["graphql"]["shortcode_media"]["edge_media_preview_like"]["count"]
      username = graphql_object["graphql"]["shortcode_media"]["owner"]["username"]

      # This has to run last since it switches pages
      user = User.lookup([username]).first

      {
        images: images,
        video: video,
        video_preview_image: video_preview_image,
        text: text,
        date: date,
        number_of_likes: number_of_likes,
        user: user,
        id: id
      }
    end
  end
end
