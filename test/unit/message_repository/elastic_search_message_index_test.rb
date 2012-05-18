require 'test_helper'

class MessageRepository
  class ElasticSearchMessageIndexTest < ActiveSupport::TestCase
    setup do
      index.reset!
    end

    def index
      @index ||= ElasticSearchMessageIndex.new
    end

    def mail
      @mail ||= mail_stub('mail')
    end

    test "#add adds the mail to the elastic search index" do
      index.add(mail)
      assert index.mail_exists?(mail.account, mail.uid)
    end

    test "#add returns a message corresponding to a mail" do
      message = index.add(mail)
      assert_equal message.message_id, mail.message_id
    end

    test "#find returns message with the recipients as those every matching message was delivered to" do
      index.add(mail_stub('mail-received-by-chris',
        account: 'chris@example.com',
        message_id: 'unique-message-id',
        delivered_to: ['chris@example.com']
      ))

      result = index.add(mail_stub('mail-received-by-tom',
        account: 'tom@example.com',
        message_id: 'unique-message-id',
        delivered_to: ['tom@example.com']
      ))

      message = index.find(result.id)
      assert_same_elements ['chris@example.com', 'tom@example.com'], message.recipients
    end

    test "#find returns message with the subject, date and from fields of the original mail" do
      result = index.add(mail)
      message = index.find(result.id)
      assert_equal message.subject, mail.subject
      assert_equal message.date, mail.date
      assert_equal message.from, mail.from
    end

    test "#find returns nil if a message with the given ID does not exist" do
      assert_nil index.find('made-up-id')
    end

    test "#find_by_message_id returns message with matching message id" do
      index.add(mail_stub('mail', message_id: 'unique-message-id', subject: 'hello', from: 'james'))
      message = index.find_by_message_id('unique-message-id')
      assert_equal 'unique-message-id', message.message_id
      assert_equal 'hello', message.subject
      assert_equal 'james', message.from
    end

    test "#find_by_message_id returns nil if no matching message was found" do
      assert_nil index.find_by_message_id('made-up-message-id')
    end

    test "#mail_exists? returns true if a matching mail has been added" do
      index.add(mail)
      assert index.mail_exists?(mail.account, mail.uid)
    end

    test "#find returns messages with message_ids that are always Strings" do
      message_id = Mail.new("Message-Id: message-id").message_id
      mail = mail_stub('mail', message_id: message_id)
      result = index.add(mail)
      message = index.find(result.id)
      assert_instance_of String, message.message_id
    end

    test "#mail_exists? returns true if a matching mail has been added to an existing message" do
      first_mail = mail_stub('mail-received-by-chris',
        account: 'chris@example.com',
        message_id: 'unique-message-id',
      )

      second_mail = mail_stub('mail-recieved-by-tom',
        account: 'tom@example.com',
        message_id: 'unique-message-id'
      )

      first_message = index.add(first_mail)
      second_message = index.add(second_mail)

      assert_equal first_message.id, second_message.id
      assert index.mail_exists?(first_mail.account, first_mail.uid)
      assert index.mail_exists?(second_mail.account, second_mail.uid)
    end

    test "#mail_exists? returns false if a matching mail has not been added" do
      refute index.mail_exists?(mail.account, mail.uid)
    end

    test "#mail_exists? requires an exact match on the account" do
      index.add(mail)
      refute index.mail_exists?('james', mail.uid)
    end

    test "#mail_exists? requires an exact match on the uid" do
      index.add(mail)
      refute index.mail_exists?(mail.account, 123)
    end

    test "#highest_uid returns the highest added uid for the given account" do
      10.times {|i| index.add(mail_stub("mail-#{i}", uid: i)) }
      assert_equal 9, index.highest_uid(mail.account)
    end

    test "#most_recent returns the requested number of most recent mails" do
      oldest_mail = mail_stub('oldest-mail', date: 3.minutes.ago)
      older_mail = mail_stub('older-mail', date: 2.minutes.ago)
      newer_mail = mail_stub('newer-mail', date: 1.minute.ago)
      index.add(oldest_mail)
      index.add(older_mail)
      index.add(newer_mail)
      recent = index.most_recent(2)
      assert_equal 2, recent.size
      assert_equal newer_mail.message_id, recent[0].message_id
      assert_equal older_mail.message_id, recent[1].message_id
    end

    test "#most_recent excludes results matching passed-in from addresses" do
      index.add(mail_stub('noisy-mail-1', from: 'a@example.com'))
      index.add(mail_stub('good-mail', from: 'b@example.com'))
      index.add(mail_stub('noisy-mail-2', from: 'c@example.com'))
      recent = index.most_recent(100, excluding: ['a@example.com', 'c@example.com'])
      assert_equal 1, recent.size
      assert_equal recent.first.from, 'b@example.com'
    end

    test "#most_recent excludes results matching wilcard addresses" do
      index.add(mail_stub('noisy-mail-1', from: 'albert@example.com'))
      index.add(mail_stub('good-mail', from: 'barry@example.com'))
      index.add(mail_stub('noisy-mail-2', from: 'andrew@example.com'))
      recent = index.most_recent(100, excluding: ['a*@example.com'])
      assert_equal 1, recent.size
      assert_equal recent.first.from, 'barry@example.com'
    end

    test "#search returns messages containing the search term in their subject" do
      index.add(mail_stub('interesting-mail', subject: 'llama zebra tiger'))
      index.add(mail_stub('interesting-mail', subject: 'zebra rabbit koala'))
      index.add(mail_stub('boring-mail', subject: 'marmoset adder penguin'))
      results = index.search('zebra')
      assert_equal 2, results.length
      assert results.detect {|r| r.subject == 'llama zebra tiger'}
      assert results.detect {|r| r.subject == 'zebra rabbit koala'}
    end

    test "#search returns messages containing the search term in their body" do
      index.add(mail_stub('interesting-mail', body: 'llama zebra tiger'))
      index.add(mail_stub('interesting-mail', body: 'zebra rabbit koala'))
      index.add(mail_stub('boring-mail', body: 'marmoset adder penguin'))
      results = index.search('zebra')
      assert_equal 2, results.length
      assert results.detect {|r| r.body == 'llama zebra tiger'}
      assert results.detect {|r| r.body == 'zebra rabbit koala'}
    end

    test "#search returns matching messages in reverse chronological order" do
      index.add(mail_stub('oldest-mail', subject: 'subject-3', date: 3.days.ago))
      index.add(mail_stub('old-mail', subject: 'subject-2', date: 2.days.ago))
      index.add(mail_stub('recent-mail', subject: 'subject-1', date: 1.day.ago))
      results = index.search('subject')
      assert_equal %w(subject-1 subject-2 subject-3), results.map(&:subject)
    end

    test "#search returns messages containing the search term as their from address" do
      index.add(mail_stub('mail-from-tom', from: 'tom@example.com'))
      index.add(mail_stub('mail-from-chris', from: 'chris@example.com'))
      results = index.search('tom@example.com')
      assert_equal 1, results.length
      assert_equal 'tom@example.com', results.first.from
    end

    test "#search returns messages containing the search term in their to addresses" do
      index.add(mail_stub('mail-1', to: ['tom@example.com', 'bob@example.com']))
      index.add(mail_stub('mail-2', to: ['chris@example.com']))
      results = index.search('tom@example.com')
      assert_equal 1, results.length
      assert_equal ['tom@example.com', 'bob@example.com'], results.first.to
    end

    test "#search returns messages containing the search term in their cc addresses" do
      index.add(mail_stub('mail-1', cc: ['tom@example.com', 'bob@example.com']))
      index.add(mail_stub('mail-2', cc: ['chris@example.com']))
      results = index.search('tom@example.com')
      assert_equal 1, results.length
      assert_equal ['tom@example.com', 'bob@example.com'], results.first.cc
    end

    test "#search ignores fields other than the subject, body, to, cc, bcc and from" do
      index.add(mail_stub('mail',
        account: 'message',
        uid: 'message',
        message_id: 'message'
      ))
      results = index.search('message')
      assert_equal 0, results.length
    end

    # Non-core behaviour (bonus features!)

    test "#add uses identifiers that respect our existing urls" do
      message = index.add(mail)
      assert_equal message.id, Digest::SHA1.hexdigest(mail.message_id)
    end
  end
end