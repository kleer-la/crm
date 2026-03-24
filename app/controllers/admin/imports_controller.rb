module Admin
  class ImportsController < BaseController
    def new
      @record_types = [ [ "Users", "user" ], [ "Customers", "customer" ], [ "Proposals", "proposal" ] ]
      @existing_counts = {
        users: User.count,
        customers: Customer.count,
        proposals: Proposal.count
      }
    end

    def preview
      unless valid_upload?
        redirect_to new_admin_import_path, alert: @upload_error
        return
      end

      @record_type = params[:record_type]
      csv_content = params[:file].read.force_encoding("UTF-8")
      @parsed = CsvImportParserService.new(csv_content, @record_type).call
      @row_count = @parsed[:rows].size

      session[:import_csv] = csv_content
      session[:import_record_type] = @record_type
    rescue CsvImportParserService::ParseError => e
      redirect_to new_admin_import_path, alert: e.message
    end

    def create
      csv_content = session.delete(:import_csv)
      record_type = session.delete(:import_record_type)

      unless csv_content && record_type
        redirect_to new_admin_import_path, alert: "No import data found. Please upload a file first."
        return
      end

      parsed = CsvImportParserService.new(csv_content, record_type).call
      @result = CsvImportExecutionService.new(parsed[:rows], record_type, current_user).call
      @record_type = record_type
    end

    private

    def valid_upload?
      if params[:file].blank?
        @upload_error = "Please select a file to upload."
        return false
      end

      unless params[:file].content_type&.include?("csv") || params[:file].original_filename&.end_with?(".csv")
        @upload_error = "Only CSV files are accepted."
        return false
      end

      if params[:record_type].blank? || !%w[user customer proposal].include?(params[:record_type])
        @upload_error = "Please select a valid record type."
        return false
      end

      true
    end
  end
end
