# frozen_string_literal: true

module Zorki
  class User
    def self.lookup(ids = [])
      # If a single id is passed in we make it the appropriate array
      ids = [ids] unless ids.kind_of?(Array)

      # Check that the ids are at least real ids
      ids.each { |id| raise Birdsong::Error if !/\A\d+\z/.match(id) }

      response = self.retrieve_data(ids)
      raise Birdsong::Error unless response.code == 200

      json_response = JSON.parse(response.body)
      json_response["data"].map do |json_user|
        User.new(json_user)
      end
    end

  private

    def initialize
    end
  end
end
