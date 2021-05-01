# frozen_string_literal: true

require_relative "zorki/version"

# Representative objects we create
require_relative "zorki/user"
require_relative "zorki/post"

require_relative "zorki/scrapers/scraper"

module Zorki
  class Error < StandardError
    def initialize(msg = "Zorki encountered an error scraping Instagram")
      super
    end
  end
  # Your code goes here...
end
