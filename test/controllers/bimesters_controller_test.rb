require "test_helper"

class BimestersControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get bimesters_create_url
    assert_response :success
  end

  test "should get destroy" do
    get bimesters_destroy_url
    assert_response :success
  end
end
