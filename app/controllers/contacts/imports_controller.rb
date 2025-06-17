class Contacts::ImportsController < ApplicationController
  include AccountScoped

  before_action :set_import, only: %i[ show edit update destroy ]

  def show
  end

  def new
    @import = Import.new
  end

  def edit
  end

  def create
    @import = @account.imports.create!(import_params)
    redirect_to edit_account_contacts_import_path(@account, @import)
  end

  def update
    redirect_to account_contacts_path(@account), notice: "Contacts imported"
  end

  def destroy
    @import.destroy
    redirect_to account_contacts_path(@account), notice: "Note: We're undoing your last vCard import. This process might take a few minutes to complete."
  end

  private
    def set_import
      @import = @account.imports.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:file)
    end
end
