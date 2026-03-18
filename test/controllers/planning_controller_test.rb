require "test_helper"

class PlanningControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get planning_index_url
    assert_response :success
  end
end
