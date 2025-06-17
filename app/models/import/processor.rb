class Import::Processor
  def initialize(import)
    @import = import
  end

  def run
    Import.transaction { import_contacts }
  rescue StandardError => e
    failed_with! e.message
  end

  private
    EMAIL_MAX_LENGTH = 254

    def import_contacts
      create_contacts_from_file
      success!
    end

    def failed_with!(message)
      @import.update! status: :failed, failed_reason: message
    end

    def create_contacts_from_file
      vcards = Vpim::Vcard.decode(@import.file.download)
      vcards.each { |vcard| create_records_from(vcard) }
    end

    def success!
      @import.contacts.exists? ? @import.processed! : @import.no_new_contacts!
    end

    def create_records_from(vcard)
      @import.account.contacts.create! name: name_for(vcard), email_address: email_for(vcard), import: @import
    rescue ActiveRecord::StatementInvalid
      @import.skipped_contacts.create! name: name_for(vcard)
    end

    def name_for(vcard)
      (vcard.name.fullname.presence || vcard.name.formatted.presence).try(:first, 1024)
    rescue Vpim::InvalidEncodingError
      # Missing mandatory N field
    end

    def email_for(vcard)
      vcard.email.downcase if valid_email?(vcard.email)
    end

    def valid_email?(email_address)
      email_address.present? && email_address.length <= EMAIL_MAX_LENGTH && email_address.match?(URI::MailTo::EMAIL_REGEXP)
    end
end
