class ProcessMessagesJob < ApplicationJob
  queue_as :default

  def perform(chat_id = nil)
    if chat_id
      # Process messages for a specific chat
      process_message_queue(chat_id)
    else
      # Process messages for all chats
      process_all_message_queues
    end
  end

  private

  # Process message queue for a specific chat
  def process_message_queue(chat_id)
    Rails.logger.info "Processing Chat with ID: #{chat_id}"
    queue_key = "chat:#{chat_id}:message_queue"

    # Check if the queue is empty
    if REDIS.llen(queue_key).zero?
      Rails.logger.info("Skipping processing for empty queue: #{queue_key}")
      return
    end

    # Fetch and bulk create messages
    bulk_create_messages(queue_key, chat_id)
  end

  # Process message queues for all chats
  def process_all_message_queues
    Rails.logger.info "Processing all message queues for all chats"

    # Find all chat message queues
    chat_keys = REDIS.keys("chat:*:message_queue")
    Rails.logger.info("Found #{chat_keys.size} chat message queues to process")

    chat_keys.each do |queue_key|
      chat_id = queue_key.match(/chat:(\d+):message_queue/)[1]
      process_message_queue(chat_id)
    end
  end

  # Bulk create messages from the queue
  def bulk_create_messages(queue_key, chat_id)
    # Fetch all messages from the Redis queue
    messages_data = []
    REDIS.pipelined do
      while (message = REDIS.rpop(queue_key))
        messages_data << JSON.parse(message)
      end
    end

    Rails.logger.info("Processing #{messages_data.size} messages for chat ID #{chat_id}")

    # Prepare messages for bulk insert
    messages = messages_data.map do |data|
      Message.new(
        chat_id: chat_id,
        body: data['body'],
        number: data['number'],
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    # Perform bulk insert
    Message.import(messages, validate: true)

    Rails.logger.info("Successfully processed #{messages.size} messages for chat ID #{chat_id}")
  rescue StandardError => e
    Rails.logger.error("Bulk message creation failed: #{e.message}")
  end
end
