require "test_helper"
require "contact"

class ContactTest < ActiveSupport::TestCase
  test "should store multiple phone numbers" do
    phone_numbers = ["0113 496 0123", "028 9018 1337"]
    contact = Contact.create!(
      name: "Name", phone_numbers: phone_numbers,
      contactotron_id: 1
    )
    assert_equal phone_numbers, contact.reload.phone_numbers
  end

  test "should import contact details from contactotron" do
    stub_request(:get, "#{Plek.current.find("contactotron")}/contacts/189").
      to_return(body: File.read(File.join(PROJECT_ROOT, "test", "fixtures", "contactotron_api_response.json")))
    contact = Contact.new(contactotron_id: 189)
    contact.update_from_contactotron
    contact.reload
    assert_equal "Contact Name", contact.name
    assert_equal "contact@example.com", contact.email_address
  end
end
