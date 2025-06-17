class Import < ApplicationRecord
  belongs_to :account

  has_many :contacts, dependent: :destroy_async
  has_many :skipped_contacts, dependent: :delete_all

  has_one_attached :file

  after_create_commit :process_file_later
  after_update_commit :broadcast_refresh_later

  enum status: %w[ processing failed processed no_new_contacts ].index_by(&:itself)

  def process_file
    Processor.new(self).run
  end

  def process_file_later
    ImportJob.set(wait: 5.seconds).perform_later(self)
  end
end
