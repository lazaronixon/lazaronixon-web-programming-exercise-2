class CreateImportSkippedContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :import_skipped_contacts do |t|
      t.references :import
      t.string :name

      t.timestamps
    end
  end
end
