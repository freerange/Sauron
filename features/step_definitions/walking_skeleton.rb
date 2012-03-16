Given /^some messages exist on the server$/ do
  GmailAccount.stubs(:messages).returns([Mail.new("Subject: Message one\nDate: 2012-05-23 12:34:45\nFrom: Dave"),
                                         Mail.new("Subject: Message two\nDate: 2012-06-22 09:21:31\nFrom: Barry")])
end

Then /^they should be visible on the messages page$/ do
  visit "/"
  within ".message" do
    assert page.has_css? ".subject", "Message one"
    assert page.has_css? ".date", "2012-05-23 12:34:45"
    assert page.has_css? ".sender", "Dave"
  end
  within ".message" do
    assert page.has_css? ".subject", "Message two"
    assert page.has_css? ".date", "2012-06-22 09:21:31"
    assert page.has_css? ".sender", "Barry"
  end
end