class ProcessChatsJob < ApplicationJob
  queue_as :default



  def perform(application_id = nil)
    if application_id
      # Process a specific application's chat queue
      process_chat_queue(application_id)
    else
      # Process all application chat queues
      process_all_chat_queues
    end
  end

  def process_chat_queue(application_id)
    Rails.logger.info "Processing Application with ID: #{application_id}"
    queue_key = "application:#{application_id}:chat_queue"
  
    # Check if the queue is empty
    if REDIS.llen(queue_key).zero?
      Rails.logger.info("Skipping processing for empty queue: #{queue_key}")
      return
    end
  
    # Fetch and bulk create chats
    bulk_create_chats(queue_key, application_id)
  end
  
  # Process chat queues for all applications
  def process_all_chat_queues
    Rails.logger.info "Processing all chat queues for all applications"
  
    # Find all application chat queues
    application_keys = REDIS.keys("application:*:chat_queue")
    Rails.logger.info("Found #{application_keys.size} application chat queues to process")
  
    application_keys.each do |queue_key|
      application_id = queue_key.match(/application:(\d+):chat_queue/)[1]
      process_chat_queue(application_id)
    end
  end

  # Bulk create chats from the queue
  def bulk_create_chats(queue_key, application_id)
    # Fetch all queued chats from Redis
    chat_data_list = []
    REDIS.pipelined do
      while (chat_data = REDIS.rpop(queue_key))
        chat_data_list << JSON.parse(chat_data)
      end
    end

    Rails.logger.info("Processing #{chat_data_list.size} chats for application ID #{application_id}")

    # Prepare chats for bulk insert
    chats = chat_data_list.map do |data|
      Chat.new(
        application_id: data['application_id'],
        number: data['number'],
        created_at: Time.current,
        updated_at: Time.current
      )
    end

    # Perform bulk insert
    Chat.import(chats, validate: true)

    # Initialize Redis counters for messages
    chats.each do |chat|
      REDIS.set("chat:#{chat.id}:message_number", chat.messages_count || 0)
      REDIS.expire("chat:#{chat.id}:message_number", 3600) # Expire after 1 hour
    end

    Rails.logger.info("Successfully processed #{chats.size} chats for application ID #{application_id}")
  rescue StandardError => e
    Rails.logger.error("Bulk chat creation failed: #{e.message}")
  end
end