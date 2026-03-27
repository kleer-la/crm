class CustomersController < ApplicationController
  include Sortable

  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  SORT_FIELDS = %i[company_name status industry total_revenue date_became_customer last_activity_date].freeze

  def index
    @customers = Customer.includes(:responsible_consultant)
    @customers = apply_filters(@customers)
    @customers = apply_sort(@customers, allowed_fields: SORT_FIELDS, default_field: :company_name, default_dir: :asc)
  end

  def show
    @contacts = @customer.contacts.order(primary: :desc, name: :asc)
  end

  def new
    @customer = Customer.new(date_became_customer: Date.current, last_activity_date: Date.current, status: :active)
    @customer.contacts.build(primary: true)
  end

  def create
    @customer = Customer.new(customer_params)
    @customer.date_became_customer ||= Date.current
    @customer.last_activity_date ||= Date.current

    if @customer.save
      redirect_to @customer, notice: "Customer was successfully created."
    else
      @customer.contacts.build(primary: true) if @customer.contacts.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @customer.destroy
      redirect_to customers_path, notice: "Customer was successfully deleted."
    else
      redirect_to @customer, alert: "Cannot delete customer with associated proposals or tasks."
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :company_name, :industry, :country, :status, :strategy,
      :responsible_consultant_id, :date_became_customer, :last_activity_date,
      collaborating_consultant_ids: [],
      contacts_attributes: [ :id, :name, :email, :phone, :role_title, :primary, :_destroy ]
    )
  end

  def apply_filters(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(responsible_consultant_id: params[:consultant_id]) if params[:consultant_id].present?
    scope = scope.where(industry: params[:industry]) if params[:industry].present?
    scope = scope.where("company_name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    scope
  end
end
