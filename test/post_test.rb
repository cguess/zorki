# frozen_string_literal: true

require "test_helper"

class PostTest < Minitest::Test
  # Note: if this fails, check the account, the number may just have changed
  # We're using Pete Souza because Obama's former photographer isn't likely to be taken down
  def test_a_single_image_post_returns_properly_when_scraped
    post = Zorki::Post.lookup(["COOCAfCFpkP"]).first
    assert_equal post.images.count, 1
  end

  def test_a_slideshow_post_returns_properly_when_scraped
    post = Zorki::Post.lookup(["CNJJM2elXQ0"]).first
    assert_equal post.images.count, 3
    assert post.text.start_with? "Opening Day 2010"
    assert_equal post.date, DateTime.parse("Apr 1, 2021")
    assert number_of_likes > 1
    assert post.user.type_of?(Zorki::User)
    assert_equal post.user.username, "petesouza"
    assert_equal post.id, "CNJJM2elXQ0ß"
  end
end
