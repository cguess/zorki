# frozen_string_literal: true

require_relative "zorki/version"
require_relative "zorki/user"
require_relative "zorki/scrapers/scraper"

module Zorki
  class Error < StandardError
    def initialize(msg="Zorki encoutered an error scraping Instagram")
      super
    end
  end
  # Your code goes here...
end
