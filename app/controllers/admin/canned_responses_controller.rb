module Admin
  class CannedResponsesController < BaseController
    before_action :set_canned_response, only: [ :edit, :update, :destroy ]

    def index
      @canned_responses = CannedResponse.ordered
    end

    def new
      @canned_response = CannedResponse.new
    end

    def create
      @canned_response = CannedResponse.new(canned_response_params)
      if @canned_response.save
        redirect_to admin_canned_responses_path, notice: "Quick reply created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @canned_response.update(canned_response_params)
        redirect_to admin_canned_responses_path, notice: "Quick reply updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @canned_response.destroy
      redirect_to admin_canned_responses_path, notice: "Quick reply deleted."
    end

    private

    def set_canned_response
      @canned_response = CannedResponse.find(params[:id])
    end

    def canned_response_params
      params.require(:canned_response).permit(:name, :content, :position)
    end
  end
end
