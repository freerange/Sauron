require 'net/imap'

module FakeGmail
  class Server
    class Account
      def add_message(mailbox, message)
        mailboxes[mailbox] << message.object_id
        messages[message.object_id] = message.to_s
      end

      def mailboxes
        @mailboxes ||= Hash.new do |hash, key|
          hash[key] = []
        end
      end

      def messages
        @messages ||= {}
      end
    end

    def accounts
      @accounts ||= Hash.new do |hash, key|
        hash[key] = Account.new
      end
    end
  end

  mattr_accessor :server
  self.server ||= Server.new

  class Connection
    def initialize(email, password)
      @email = email
      @password = password
    end

    def examine(mailbox)
      @mailbox = mailbox
    end

    def uid_search(name)
      raise 'Mock only supports ALL' unless name == 'ALL'
      account.mailboxes[@mailbox]
    end

    def uid_fetch(uids, scope)
      uids = [*uids]
      raise 'Mock only supports BODY.PEEK[]' unless scope == 'BODY.PEEK[]'
      uids.map do |uid|
        Net::IMAP::FetchData.new(1, 'UID' => uid, 'BODY[]' => account.messages[uid])
      end
    end

    def server
      FakeGmail.server
    end

    def account
      server.accounts[@email]
    end
  end
end