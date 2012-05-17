ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
require 'fakes/fake_gmail'

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...

  def assert_same_elements(expected, actual, message=nil)
    assert_equal expected.sort, actual.sort, message
  end

  def mail_stub(attributes = {})
    stub("GoogleMail::Mailbox::Mail", {
      account: 'james@example.com',
      uid: rand(100000),
      message_id: SecureRandom.hex,
      subject: 'an-example-email',
      from: 'liam@example.com',
      to: ['baz@example.com'],
      cc: ['mike@example.com'],
      date: Time.utc(2012, 7, 27, 20, 00, 00),
      delivered_to: ['james@example.com'],
      body: 'Any old body'
    }.merge(attributes)).responds_like(GoogleMail::Mailbox::Mail.new(nil, nil, nil))
  end

  def message_stub(attributes = {})
    stub('message', {
      recipients: [],
      to: [],
      sent_or_received_by?: false,
      date: Time.now,
      subject: 'subject',
      from: 'sender',
      body: 'body',
      displayable_raw_mail: 'displayable-raw-mail'
    }.merge(attributes)).responds_like(MessageRepository::Message.new(nil, nil))
  end

  def conversation_stub(stub_name, attributes = {})
    stub(stub_name, {
      latest_message_date: Time.now,
      subject: 'subject',
    }.merge(attributes)).responds_like(ConversationRepository::Conversation.new)
  end

  def stub_message(name, attributes={})
    stub(name, {
      date: 1.minute.ago,
      subject: 'subject',
      in_reply_to: nil,
      message_id: SecureRandom.hex
    }.merge(attributes)).responds_like(MessageRepository::Message.new(nil, nil))
  end

  def stub_reply_to(message, name, attributes={})
    stub_message(name, {in_reply_to: message.message_id, subject: message.subject}.merge(attributes))
  end
end

Mocha::Configuration.prevent(:stubbing_non_existent_method)
