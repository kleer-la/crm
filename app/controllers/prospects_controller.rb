class ProspectsController < ApplicationController
  include Sortable

  before_action :set_prospect, only: [ :show, :edit, :update, :destroy, :disqualify, :convert ]
  before_action :ensure_not_converted, only: [ :edit, :update, :destroy, :disqualify ]

  SORT_FIELDS = %i[company_name status source estimated_value date_added last_activity_date].freeze

  def index
    @prospects = Prospect.includes(:responsible_consultant)
    @prospects = apply_filters(@prospects)
    @prospects = apply_sort(@prospects, allowed_fields: SORT_FIELDS, default_field: :date_added)
    @prospects = @prospects.page(params[:page]) if @prospects.respond_to?(:page)
  end

  def show
  end

  def new
    @prospect = Prospect.new(date_added: Date.current, last_activity_date: Date.current, status: :new_prospect)
  end

  def create
    @prospect = Prospect.new(prospect_params)
    @prospect.date_added ||= Date.current
    @prospect.last_activity_date ||= Date.current

    if @prospect.save
      redirect_to @prospect, notice: "Prospect was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prospect.update(prospect_params)
      redirect_to @prospect, notice: "Prospect was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @prospect.destroy!
    redirect_to prospects_path, notice: "Prospect was successfully deleted."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to @prospect, alert: "Cannot delete prospect with associated proposals or tasks."
  end

  def disqualify
    if params[:prospect][:disqualification_reason].blank?
      redirect_to @prospect, alert: "Disqualification reason is required."
      return
    end

    @prospect.update!(
      status: :disqualified,
      disqualification_reason: params[:prospect][:disqualification_reason]
    )
    redirect_to @prospect, notice: "Prospect has been disqualified."
  rescue ActiveRecord::RecordInvalid
    redirect_to @prospect, alert: @prospect.errors.full_messages.to_sentence
  end

  def convert
    service = ConvertProspectService.new(@prospect, current_user)
    customer = service.call

    redirect_to customer, notice: "Prospect converted to customer successfully."
  rescue ConvertProspectService::ConversionError => e
    redirect_to @prospect, alert: e.message
  end

  private

  def set_prospect
    @prospect = Prospect.find(params[:id])
  end

  def ensure_not_converted
    if @prospect.read_only?
      redirect_to @prospect, alert: "This prospect has been converted and is read-only."
    end
  end

  def prospect_params
    params.require(:prospect).permit(
      :company_name, :primary_contact_name, :primary_contact_email,
      :primary_contact_phone, :industry, :source, :status,
      :estimated_value, :responsible_consultant_id,
      :date_added, :last_activity_date,
      collaborating_consultant_ids: []
    )
  end

  def apply_filters(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(responsible_consultant_id: params[:consultant_id]) if params[:consultant_id].present?
    scope = scope.where(industry: params[:industry]) if params[:industry].present?
    scope = scope.where("company_name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    scope
  end
end
