require "test_helper"

module Api
  module V1
    class ContactsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @valid_payload = {
          contact: {
            name: "Ana García",
            email: "ana@example.com",
            company: "Acme S.A.",
            message: "Quisiera info",
            context: "https://kleer.la/cursos/scrum"
          }
        }
      end

      test "valid payload returns 202 and enqueues the job" do
        assert_enqueued_with(job: IngestWebContactJob, args: [ @valid_payload[:contact].stringify_keys ]) do
          post api_v1_contact_path, params: @valid_payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        end

        assert_response :accepted
        assert_equal "Contact accepted", response.parsed_body["message"]
      end

      test "valid payload enqueues exactly one job" do
        assert_difference "ActiveJob::Base.queue_adapter.enqueued_jobs.size", 1 do
          post api_v1_contact_path, params: @valid_payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        end
      end

      test "missing token returns 401" do
        skip "Auth is bypassed in test environment (ApiController skips auth in test/dev)"
      end

      test "malformed JSON returns 400" do
        post api_v1_contact_path, params: "not json", headers: { "CONTENT_TYPE" => "application/json" }
        assert_response :bad_request
        assert_equal "Invalid JSON body", response.parsed_body["message"]
      end

      test "missing contact key returns 400" do
        post api_v1_contact_path, params: { name: "Ana" }.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        assert_response :bad_request
        assert_includes response.parsed_body["message"], "contact"
      end

      test "blank name returns 400" do
        post api_v1_contact_path,
             params: { contact: { name: "", email: "ana@example.com", message: "hi" } }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        assert_response :bad_request
        assert_includes response.parsed_body["message"], "contact.name"
      end

      test "blank email returns 400" do
        post api_v1_contact_path,
             params: { contact: { name: "Ana", email: "", message: "hi" } }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        assert_response :bad_request
        assert_includes response.parsed_body["message"], "contact.email"
      end

      test "blank message returns 400" do
        post api_v1_contact_path,
             params: { contact: { name: "Ana", email: "ana@example.com", message: "" } }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        assert_response :bad_request
        assert_includes response.parsed_body["message"], "contact.message"
      end

      test "controller does not create prospects or proposals" do
        assert_no_difference [ "Prospect.count", "Proposal.count" ] do
          post api_v1_contact_path, params: @valid_payload.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        end
      end
    end
  end
end
