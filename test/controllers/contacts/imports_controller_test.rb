require "test_helper"

class Contacts::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup { @account = accounts(:basecamp) }

  test "new import" do
    get new_account_contacts_import_url(@account)
    assert_response :success
  end

  test "creating import with new contacts" do
    assert_difference "Import.count" do
      post account_contacts_imports_url(@account), params: { import: { file: david_vcf } }
      perform_enqueued_jobs
    end

    follow_redirect!
    assert_select "h1", "Does this look right?"
  end

  test "creating import with no new contacts" do
    assert_difference "Import.count" do
      post account_contacts_imports_url(@account), params: { import: { file: rosa_vcf } }
      perform_enqueued_jobs
    end

    follow_redirect!
    assert_select "h1", "We couldn’t find any new contacts to import."
  end

  test "creating import with invalid file" do
    assert_difference "Import.count" do
      post account_contacts_imports_url(@account), params: { import: { file: invalid_vcf } }
      perform_enqueued_jobs
    end

    follow_redirect!
    assert_select "h1", "We had some trouble importing that vCard."
  end

  test "creating import with delay" do
    assert_difference "Import.count" do
      post account_contacts_imports_url(@account), params: { import: { file: david_vcf } }
    end

    follow_redirect!
    assert_select "h1", "Just a moment, please, while we process your import"
  end

  test "showing import with new contacts" do
    get account_contacts_import_url(@account, imports(:lazaro_nixon))
    assert_select "section", /You imported 1 new contact/
    assert_select "section", /We skipped 1 duplicate contact/
    assert_select "button", "Undo this import"
  end

  test "showing import with no new contacts" do
    imports(:lazaro_nixon).no_new_contacts!
    imports(:lazaro_nixon).contacts.delete_all
    imports(:lazaro_nixon).skipped_contacts.delete_all

    get account_contacts_import_url(@account, imports(:lazaro_nixon))
    assert_select "section", "No new contacts were imported."
    assert_select "a", "Try another import"
  end

  test "showing import with invalid file" do
    imports(:lazaro_nixon).failed!
    imports(:lazaro_nixon).contacts.delete_all
    imports(:lazaro_nixon).skipped_contacts.delete_all

    get account_contacts_import_url(@account, imports(:lazaro_nixon))
    assert_select "section", "No new contacts were imported."
    assert_select "a", "Try another import"
  end

  test "showing import with delay" do
    imports(:lazaro_nixon).processing!
    imports(:lazaro_nixon).contacts.delete_all
    imports(:lazaro_nixon).skipped_contacts.delete_all

    get account_contacts_import_url(@account, imports(:lazaro_nixon))
    assert_select "section", /This import is still in progress/
    assert_select "a", "Go back"
  end

  test "confirming import" do
    patch account_contacts_import_url(@account, imports(:lazaro_nixon))
    follow_redirect!

    assert_select "h1", "Contacts"
    assert_select "div", "Contacts imported"
  end

  test "undoing import" do
    assert_difference  "Import.count" => -1, "Import::SkippedContact.count" => -1, "Contact.count" => -1 do
      delete account_contacts_import_url(@account, imports(:lazaro_nixon))
      perform_enqueued_jobs
    end

    follow_redirect!

    assert_select "h1", "Contacts"
    assert_select "div", /We're undoing your last vCard import/
  end

  private
    def david_vcf
      fixture_file_upload("david.vcf", "text/plain")
    end

    def rosa_vcf
      fixture_file_upload("rosa.vcf", "text/plain")
    end

    def invalid_vcf
      fixture_file_upload "invalid.vcf", "text/plain"
    end
end
