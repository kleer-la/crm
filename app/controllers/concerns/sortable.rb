module Sortable
  extend ActiveSupport::Concern

  private

  def apply_sort(scope, allowed_fields:, default_field: :created_at, default_dir: :desc)
    field = allowed_fields.include?(params[:sort]&.to_sym) ? params[:sort] : default_field.to_s
    dir = %w[asc desc].include?(params[:dir]) ? params[:dir] : default_dir.to_s
    scope.order(field => dir)
  end
end
