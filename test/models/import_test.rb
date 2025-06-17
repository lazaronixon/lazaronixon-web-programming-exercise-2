require "test_helper"

class ImportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess

  setup { @account = accounts(:basecamp) }

  test "import file with new contacts" do
    import = @account.imports.create!(file: fixture_file_upload("david.vcf", "text/plain"))
    perform_enqueued_jobs

    assert import.reload.processed?
    assert_equal 0, import.skipped_contacts.size
    assert_equal 1, import.contacts.size
  end

  test "import file with no new contacts" do
    import = @account.imports.create!(file: fixture_file_upload("rosa.vcf", "text/plain"))
    perform_enqueued_jobs

    assert import.reload.no_new_contacts?
    assert_equal 1, import.skipped_contacts.size
    assert_equal 0, import.contacts.size
  end

  test "import file with failure" do
    import = @account.imports.create!(file: fixture_file_upload("invalid.vcf", "text/plain"))
    perform_enqueued_jobs

    assert import.reload.failed?
    assert_equal 0, import.skipped_contacts.size
    assert_equal 0, import.contacts.size
  end

  test "import file with invalid name" do
    import = @account.imports.create!(file: fixture_file_upload("invalid_name.vcf", "text/plain"))
    perform_enqueued_jobs

    assert import.reload.processed?
    assert_equal 0, import.skipped_contacts.size
    assert_equal 1, import.contacts.size
  end

  test "import file with invalid email" do
    import = @account.imports.create!(file: fixture_file_upload("invalid_email.vcf", "text/plain"))
    perform_enqueued_jobs

    assert import.reload.no_new_contacts?
    assert_equal 1, import.skipped_contacts.size
    assert_equal 0, import.contacts.size
  end

  test "import file with invalid name and email" do
    import = @account.imports.create!(file: fixture_file_upload("invalid_name_and_email.vcf", "text/plain"))
    perform_enqueued_jobs

    assert import.reload.no_new_contacts?
    assert_equal 1, import.skipped_contacts.size
    assert_equal 0, import.contacts.size
  end

  test "undo file import" do
    assert_difference  "Import.count" => -1, "Import::SkippedContact.count" => -1, "Contact.count" => -1 do
      imports(:lazaro_nixon).destroy
      perform_enqueued_jobs
    end
  end
end
