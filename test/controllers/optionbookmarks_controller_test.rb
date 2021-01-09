require "test_helper"

class OptionbookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @optionbookmark = optionbookmarks(:one)
  end

  test "should get index" do
    get optionbookmarks_url
    assert_response :success
  end

  test "should get new" do
    get new_optionbookmark_url
    assert_response :success
  end

  test "should create optionbookmark" do
    assert_difference('Optionbookmark.count') do
      post optionbookmarks_url, params: { optionbookmark: { longleg: @optionbookmark.longleg, shortleg: @optionbookmark.shortleg, user_id: @optionbookmark.user_id } }
    end

    assert_redirected_to optionbookmark_url(Optionbookmark.last)
  end

  test "should show optionbookmark" do
    get optionbookmark_url(@optionbookmark)
    assert_response :success
  end

  test "should get edit" do
    get edit_optionbookmark_url(@optionbookmark)
    assert_response :success
  end

  test "should update optionbookmark" do
    patch optionbookmark_url(@optionbookmark), params: { optionbookmark: { longleg: @optionbookmark.longleg, shortleg: @optionbookmark.shortleg, user_id: @optionbookmark.user_id } }
    assert_redirected_to optionbookmark_url(@optionbookmark)
  end

  test "should destroy optionbookmark" do
    assert_difference('Optionbookmark.count', -1) do
      delete optionbookmark_url(@optionbookmark)
    end

    assert_redirected_to optionbookmarks_url
  end
end
