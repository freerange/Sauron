require "test_helper"

class MessageRepository
  class ActiveRecordMessageIndexTest < ActiveSupport::TestCase
    test "returns the 2500 most recent messages excluding duplicates" do
      most_recent_records = [ActiveRecordMessageIndex.new]
      ActiveRecordMessageIndex.stubs(:all).with(order: "date DESC", limit: 500, group: :message_id).returns(most_recent_records)
      assert_equal most_recent_records, ActiveRecordMessageIndex.most_recent
    end

    test ".message_exists? returns a truthy value if a message exists matching the account and uid" do
      given_message_exists_in_database(account = "a@b.com", uid = 2)
      assert ActiveRecordMessageIndex.message_exists?(account, uid)
    end

    test ".message_exists? returns a falsey value if no message exists matching the account and uid" do
      given_message_does_not_exist_in_database(account = "a@b.com", uid = 2)
      refute ActiveRecordMessageIndex.message_exists?(account, uid)
    end

    test ".highest_uid returns nil if there are no messages" do
      given_no_messages_exist_in_database(account = "a@b.com")
      assert_nil ActiveRecordMessageIndex.highest_uid(account)
    end

    test ".highest_uid returns highest UID" do
      given_message_with_highest_uid_exists_in_database(account = "a@b.com", uid = 999)
      assert_equal uid, ActiveRecordMessageIndex.highest_uid(account)
    end

    test ".add(message) adds message by creating a model" do
      message = stub('message', account: 'sam@example.com', uid: 123, subject: 'Subject', from: 'tom@example.com', date: Date.today, message_id: "message-id")
      ActiveRecordMessageIndex.expects(:create!).with(account: 'sam@example.com', uid: 123, subject: 'Subject', from: 'tom@example.com', date: Date.today, message_id: "message-id")
      ActiveRecordMessageIndex.add(message)
    end

    private

    def given_message_exists_in_database(account, uid)
      ActiveRecordMessageIndex.stubs(:exists?).with(account: account, uid: uid).returns(true)
    end

    def given_message_does_not_exist_in_database(account, uid)
      ActiveRecordMessageIndex.stubs(:exists?).with(account: account, uid: uid).returns(false)
    end

    def given_message_with_highest_uid_exists_in_database(account, uid)
      scope = stub("scope") { stubs(:maximum).with(:uid).returns(uid) }
      ActiveRecordMessageIndex.stubs(:where).with(account: account).returns(scope)
    end

    def given_no_messages_exist_in_database(account)
      scope = stub("scope") { stubs(:maximum).with(:uid).returns(nil) }
      ActiveRecordMessageIndex.stubs(:where).with(account: account).returns(scope)
    end
  end
end