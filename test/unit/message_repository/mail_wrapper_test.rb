# encoding: utf-8
require "test_helper"

class MessageRepository
  class MailWrapperTest < ActiveSupport::TestCase
    test "returns the sender defined by the From: header" do
      raw_message = Mail.new(from: "bob@example.com").to_s
      assert_equal "bob@example.com", MailWrapper.new(raw_message).from
    end

    test "returns nil when the message doesn't include a From: header" do
      raw_message = Mail.new(from: nil).to_s
      assert_nil MailWrapper.new(raw_message).from
    end

    test "returns the subject" do
      raw_message = Mail.new(subject: "email-subject").to_s
      assert_equal "email-subject", MailWrapper.new(raw_message).subject
    end

    test "handles pound signs encoded in Windows-1252 in the subject" do
      subject_with_invalid_encoding = "It costs \xA320. Bargain!".force_encoding("ASCII-8BIT")
      raw_message = "Subject: #{subject_with_invalid_encoding}"
      assert_equal "It costs £20. Bargain!", MailWrapper.new(raw_message).subject
    end

    test "handles ellipsis characters encoded in Windows-1252 in the subject" do
      subject_with_invalid_encoding = "Before \x85 After".force_encoding("ASCII-8BIT")
      raw_message = "Subject: #{subject_with_invalid_encoding}"
      assert_equal "Before … After", MailWrapper.new(raw_message).subject
    end

    test "handles en dashes encoded in Windows-1252 in the subject" do
      subject_with_invalid_encoding = "This \x96 that".force_encoding("ASCII-8BIT")
      raw_message = "Subject: #{subject_with_invalid_encoding}"
      assert_equal "This – that", MailWrapper.new(raw_message).subject
    end

    test "handles e-umlaut characters encoded in Windows-1252 in the subject" do
      subject_with_invalid_encoding = "This \xEB that".force_encoding("ASCII-8BIT")
      raw_message = "Subject: #{subject_with_invalid_encoding}"
      assert_equal "This ë that", MailWrapper.new(raw_message).subject
    end

    test "doesn't attempt to handle characters outside of those windows-1252 characters that we've encountered in the wild, so that we fail fast" do
      subject_with_invalid_encoding = "This \xA6 that".force_encoding("ASCII-8BIT")
      raw_message = "Subject: #{subject_with_invalid_encoding}"
      assert_equal "This \xA6 that".force_encoding("ASCII-8BIT"), MailWrapper.new(raw_message).subject # ¦
    end

    test "it doesn't do any conversion for strings that are already UTF-8" do
      utf_8_subject = "Unicode = \u00A3".encode("UTF-8")
      raw_message = "Subject: #{utf_8_subject}"
      assert_equal "Unicode = £", MailWrapper.new(raw_message).subject
    end

    test "returns nil when the message has an empty Subject header" do
      raw_message = Mail.new(subject: nil).to_s
      assert_nil MailWrapper.new(raw_message).subject
    end

    test "returns the date" do
      raw_message = Mail.new(date: "2012-01-01 09:00:00").to_s
      assert_equal Time.parse("2012-01-01 09:00:00"), MailWrapper.new(raw_message).date
    end
  end
end