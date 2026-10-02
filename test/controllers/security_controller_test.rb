require "test_helper"

class SecurityControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get security_index_url
    assert_response :success
  end

  test "should get update" do
    get security_update_url
    assert_response :success
  end
end
