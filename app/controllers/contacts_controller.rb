class ContactsController < ApplicationController
  before_action :set_customer
  before_action :set_contact, only: [ :edit, :update, :destroy ]

  def new
    @contact = @customer.contacts.build
  end

  def create
    @contact = @customer.contacts.build(contact_params)

    enforce_single_primary if @contact.primary?

    if @contact.save
      redirect_to @customer, notice: "Contact was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @contact.assign_attributes(contact_params)

    enforce_single_primary if @contact.primary? && @contact.primary_changed?

    if @contact.save
      redirect_to @customer, notice: "Contact was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @customer.contacts.count <= 1
      redirect_to @customer, alert: "Cannot remove the last contact."
      return
    end

    was_primary = @contact.primary?
    @contact.destroy!

    if was_primary && @customer.contacts.any?
      @customer.contacts.order(:created_at).first.update!(primary: true)
    end

    redirect_to @customer, notice: "Contact was successfully removed."
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_contact
    @contact = @customer.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :phone, :role_title, :primary)
  end

  def enforce_single_primary
    @customer.contacts.where.not(id: @contact.id).update_all(primary: false)
  end
end
