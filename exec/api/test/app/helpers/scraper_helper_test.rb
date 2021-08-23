require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

describe "Api::App::ScraperHelper" do
  before do
    @helpers = Class.new
    @helpers.extend Api::App::ScraperHelper
  end

  def helpers
    @helpers
  end

  it "should return nil" do
    assert_nil helpers.foo
  end
end
