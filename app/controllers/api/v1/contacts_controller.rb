module Api
  module V1
    class ContactsController < Api::ApiController
      def create
        body = request.body.read
        data = JSON.parse(body)
        contact = data["contact"]

        if contact.blank?
          return render status: :bad_request, json: { message: "Missing required field: contact" }
        end

        missing = %w[name email message].select { |f| contact[f].blank? }
        if missing.any?
          fields = missing.map { |f| "contact.#{f}" }.join(", ")
          return render status: :bad_request, json: { message: "Missing required fields: #{fields}" }
        end

        IngestWebContactJob.perform_later(contact)
        render status: :accepted, json: { message: "Contact accepted" }
      rescue JSON::ParserError
        render status: :bad_request, json: { message: "Invalid JSON body" }
      end
    end
  end
end
