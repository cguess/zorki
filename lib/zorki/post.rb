# frozen_string_literal: true

module Zorki
  class Post
    def self.lookup(ids = [])
      # If a single id is passed in we make it the appropriate array
      ids = [ids] unless ids.kind_of?(Array)

      # Check that the ids are at least real ids
      # ids.each { |id| raise Birdsong::Error if !/\A\d+\z/.match(id) }

      self.scrape(ids)
    end

    attr_reader :id,
                :images,
                :text,
                :date,
                :number_of_likes,
                :user,
                :video,
                :video_preview_image

  private

    def initialize(hash = {})
      @id = hash[:id]
      @images = hash[:images]
      @text = hash[:text]
      @date = hash[:date]
      @number_of_likes = hash[:number_of_likes]
      @user = hash[:user]
      @video = hash[:video]
      @video_preview_image = hash[:video_preview_image]
    end

    class << self
      private

        def scrape(ids)
          ids.map do |id|
            user_hash = Zorki::PostScraper.new.parse(id)
            Post.new(user_hash)
          end
        end
    end
  end
end
