class CacheBackedMessageStore
  def initialize(cache = ActiveSupport::Cache::FileStore.new(Rails.root + 'data' + Rails.env + 'messages'))
    @cache = cache
  end

  def add(account, uid, message)
    @cache.write [account, uid], message
  end

  def find(account, uid)
    @cache.read [account, uid]
  end

  class << self
    delegate :add, :find, to: :instance

    def instance
      @instance ||= new
    end

    def configure(*args)
      @instance = new(*args)
    end
  end
end