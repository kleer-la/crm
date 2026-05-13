require "json"

module Api
  module V1
    # "contact": {
    #   "name": "Ana García",
    #   "email": "ana@example.com",
    #   "company": "Acme S.A.",
    #   "message": "Quisiera info sobre fechas...",
    #   "context": "https://kleer.la/cursos/scrum"
    # }
    class ContactsController < Api::ApiController
      def create
        body = request.body.read
        data = JSON.parse(body)

        Rails.logger.debug data.inspect

        render status: :ok, json: { message: "Contact captured" }
      end

      private
    end
  end
end
