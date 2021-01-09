require "application_system_test_case"

class OptionbookmarksTest < ApplicationSystemTestCase
  setup do
    @optionbookmark = optionbookmarks(:one)
  end

  test "visiting the index" do
    visit optionbookmarks_url
    assert_selector "h1", text: "Optionbookmarks"
  end

  test "creating a Optionbookmark" do
    visit optionbookmarks_url
    click_on "New Optionbookmark"

    fill_in "Longleg", with: @optionbookmark.longleg
    fill_in "Shortleg", with: @optionbookmark.shortleg
    fill_in "User", with: @optionbookmark.user_id
    click_on "Create Optionbookmark"

    assert_text "Optionbookmark was successfully created"
    click_on "Back"
  end

  test "updating a Optionbookmark" do
    visit optionbookmarks_url
    click_on "Edit", match: :first

    fill_in "Longleg", with: @optionbookmark.longleg
    fill_in "Shortleg", with: @optionbookmark.shortleg
    fill_in "User", with: @optionbookmark.user_id
    click_on "Update Optionbookmark"

    assert_text "Optionbookmark was successfully updated"
    click_on "Back"
  end

  test "destroying a Optionbookmark" do
    visit optionbookmarks_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Optionbookmark was successfully destroyed"
  end
end
