require "test_helper"

class AcademicSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get academic_settings_index_url
    assert_response :success
  end
end
