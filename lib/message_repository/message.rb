class MessageRepository::Message
  attr_reader :index_record
  delegate :subject, :date, :from, :message_id, :message_hash, to: :index_record

  def initialize(index_record, store)
    @index_record = index_record
    @store = store
  end

  def recipients
    index_record.recipients.reject(&:blank?)
  end

  def received_by?(email)
    recipients.include?(email)
  end

  def body
    if parsed_mail.multipart?
      text_part_bodies(parsed_mail).join
    else
      parsed_mail.decoded
    end
  end

  def ==(message)
    message.is_a?(MessageRepository::Message) &&
    message.index_record == index_record
  end

  def raw_mail
    @raw_mail ||= @store.find(index_record.account, index_record.uid)
  end

  def to_param
    message_hash
  end

  def parsed_mail
    @parsed_mail ||= Mail.new(raw_mail)
  end

  private

  def text_part_bodies(part)
    part.parts.inject([]) do |bodies, part|
      if part.multipart?
        bodies << text_part_bodies(part)
      elsif part.content_type =~ /text\/plain/
        bodies << part.decoded
      end
      bodies.flatten
    end
  end
end
