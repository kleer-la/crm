module System
  class DeploymentsController < ApplicationController
    def index
      @page = [ (params[:page] || 1).to_i, 1 ].max
      @per_page = 20
      @total_count = Deployment.count
      @total_pages = [ (@total_count.to_f / @per_page).ceil, 1 ].max

      @deployments = Deployment.recent.limit(@per_page).offset((@page - 1) * @per_page)

      @selected_deployment = if params[:id].present?
        Deployment.find_by(id: params[:id])
      else
        Deployment.recent.first
      end
    end
  end
end
