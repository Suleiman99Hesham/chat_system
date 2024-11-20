class UpdateCountsJob < ApplicationJob
  queue_as :default
  
  def perform
    # Batch update chats_count for applications
    Application.find_each do |app|
      Rails.logger.info("Updated chats_count for Application ##{app.id}")
      app_chats_count = Chat.where(application_id: app.id).size
      app.update_columns(chats_count: app_chats_count)
    end
  
    # Batch update messages_count for chats
    Chat.find_each do |chat|
      Rails.logger.info("Updated messages_count for Chat ##{chat.id}")
      chat_messages_count = Message.where(chat_id: chat.id).size
      chat.update_columns(messages_count: chat_messages_count)
    end
  end

  
end

