require "test_helper"

class FilterParameterLoggingTest < ActiveSupport::TestCase
  setup do
    @filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  end

  test "filters message text and phone numbers from a Meta webhook payload" do
    payload = {
      "entry" => [ { "changes" => [ { "value" => {
        "contacts" => [ { "wa_id" => "5491155501002", "profile" => { "name" => "Ana" } } ],
        "messages" => [ { "id" => "wamid.1", "from" => "5491155501002", "type" => "text",
                          "text" => { "body" => "Hola, cuánto cuesta?" } } ]
      } } ] } ]
    }

    value = @filter.filter(payload)["entry"][0]["changes"][0]["value"]
    message = value["messages"][0]

    assert_equal "[FILTERED]", message["from"]
    assert_equal "[FILTERED]", message["text"]
    assert_equal "[FILTERED]", value["contacts"][0]["wa_id"]
    assert_equal "wamid.1", message["id"]
    assert_equal "text", message["type"]
  end

  test "filters outbound message content and contact form text" do
    filtered = @filter.filter(
      "message" => { "content" => "Hola", "message_type" => "text" },
      "contact" => { "message" => "Quisiera info", "phone" => "+54 11 5555", "company" => "Acme" }
    )

    assert_equal "[FILTERED]", filtered["message"]
    assert_equal "[FILTERED]", filtered["contact"]["message"]
    assert_equal "[FILTERED]", filtered["contact"]["phone"]
    assert_equal "Acme", filtered["contact"]["company"]
  end
end
