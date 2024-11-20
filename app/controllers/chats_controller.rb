class ChatsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_application

  # Cache Frequently Accessed Data
  def index
    chats = Rails.cache.fetch("application:#{@application.id}:chats", expires_in: 5.minutes) do
      @application.chats.preload(:messages)
    end
    render json: chats, each_serializer: ChatSerializer, status: :ok # Improve JSON Serialization
  end

  def show
    chat = Rails.cache.fetch("application:#{@application.id}:chat:#{params[:number]}", expires_in: 5.minutes) do
      @application.chats.includes(:messages).find_by!(number: params[:number]) # Use Preloading for Associations
    end
    render json: chat, serializer: ChatSerializer, status: :ok # Improve JSON Serialization
  end

  def create
    chat_key = "application:#{@application.id}:chat_number"

    # Check if the key exists in Redis
    REDIS.watch(chat_key) do
      unless REDIS.exists(chat_key)
        # Fetch the latest chat number from the database
        latest_chat_number = Chat.where(application_id: @application.id).maximum(:chat_number) || 0
        
        # Initialize Redis with the latest chat number
        REDIS.multi do
          REDIS.set(chat_key, latest_chat_number)
        end
      end
    end
    
    # Increment the counter
    chat_number = REDIS.incr(chat_key)
    
    # Get the threshold from Rails application configuration
    chat_queue_threshold = Rails.application.config.chat_queue_threshold

    # Queue chat creation data in Redis
    chat_data = {
      application_id: @application.id,
      number: chat_number,
    }

    REDIS.lpush("application:#{@application.id}:chat_queue", chat_data.to_json)

    # Optionally trigger batch processing if the queue size is large enough
    if REDIS.llen("application:#{@application.id}:chat_queue") >= chat_queue_threshold
      Rails.logger.info("Triggering ProcessChatsJob for application ID #{@application.id} as queue size exceeded threshold.")
      ProcessChatsJob.perform_later(@application.id)
    end

    # Set expiration for the queue to clean up stale data
    REDIS.expire("application:#{@application.id}:chat_queue", 3600) # Expire in 1 hour

    # Invalidate the cached chats list
    Rails.cache.delete("application:#{@application.id}:chats")

    render json: { chat_number: chat_number }, status: :accepted
  end

  def update
    chat = @application.chats.find_by!(number: params[:number])
    if chat.update(chat_params)
      # Invalidate cache for the updated chat
      Rails.cache.delete("application:#{@application.id}:chat:#{chat.number}")
      render json: chat, serializer: ChatSerializer
    else
      render json: { errors: chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  end

  def chat_params
    params.require(:chat).permit(:number)
  end
end
