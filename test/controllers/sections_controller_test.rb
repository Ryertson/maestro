require "test_helper"

class SectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get sections_create_url
    assert_response :success
  end
end
