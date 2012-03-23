require 'test_helper'

class MessageImporterTest < ActiveSupport::TestCase
  test 'imports messages available in the mailbox' do
    mailbox = stub('mailbox')
    mailbox.stubs(:uids).returns([3, 4])
    mailbox.stubs(:message).with(3).returns(:message1)
    mailbox.stubs(:message).with(4).returns(:message2)
    importer = MessageImporter.new(mailbox)
    repository = stub('repository', include?: false)
    repository.expects(:store).with(3, :message1)
    repository.expects(:store).with(4, :message2)
    importer.import_into(repository)
  end

  test 'skips messages already available in repository' do
    mailbox = stub('mailbox')
    mailbox.stubs(:uids).returns([5])
    mailbox.expects(:message).with(5).never
    importer = MessageImporter.new(mailbox)
    repository = stub('repository')
    repository.stubs(:include?).with(5).returns(true)
    repository.expects(:store).never
    importer.import_into(repository)
  end
end
