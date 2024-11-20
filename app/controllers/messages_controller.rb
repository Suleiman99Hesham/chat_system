class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_application
  before_action :set_chat

  def index
    # Cache Frequently Accessed Data
    # GET /applications/:application_token/chats/:chat_number/messages
    messages = Rails.cache.fetch("chat:#{@chat.id}:messages", expires_in: 5.minutes) do
      @chat.messages
    end
    render json: messages, each_serializer: MessageSerialize, status: :ok # Improve JSON Serialization
  end

  def show
    # Cache Frequently Accessed Data
    message = Rails.cache.fetch("chat:#{@chat.id}:message:#{params[:number]}", expires_in: 5.minutes) do
      @chat.messages.includes(:chat).find_by!(number: params[:number]) # Use Preloading for Associations
    end
    render json: message, serializer: MessageSerializer, status: :ok # Improve JSON Serialization
  end

  def create
    message_key = "chat:#{@chat.id}:message_number"

    # Check if the key exists in Redis
    REDIS.watch(message_key) do
      unless REDIS.exists(message_key)
        # Fetch the latest message number from the database
        latest_message_number = Message.where(chat_id: @chat.id).maximum(:message_number) || 0

        # Initialize Redis with the latest message number
        REDIS.multi do
          REDIS.set(message_key, latest_message_number)
        end
      end
    end

    # Increment the counter
    message_number = REDIS.incr(message_key)

    # Get the threshold from Rails application configuration
    message_queue_threshold = Rails.application.config.message_queue_threshold

    # Prepare message attributes
    message_data = {
      chat_id: @chat.id,
      body: params[:body],
      number: message_number
    }

    # Add the data to a Redis list
    REDIS.lpush("chat:#{@chat.id}:message_queue", message_data.to_json)

    # Optionally trigger batch processing if the queue size is large enough
    if REDIS.llen("chat:#{@chat.id}:message_queue") >= message_queue_threshold
      Rails.logger.info("Triggering ProcessMessagesJob for chat ID #{@chat.id} as queue size exceeded threshold.")
      ProcessMessagesJob.perform_later(@chat.id)
    end

    # Expire the Redis queue for messages after processing
    REDIS.expire("chat:#{@chat.id}:message_queue", 3600) # Expire after 1 hour

    # Invalidate the cached messages list
    Rails.cache.delete("chat:#{@chat.id}:messages")

    render json: { message_number: message_number }, status: :accepted
  end

  def update
    message = @chat.messages.find_by!(number: params[:number])
    if message.update(message_params)
      # Invalidate cache for the updated message
      Rails.cache.delete("chat:#{@chat.id}:message:#{message.number}")
      render json: message, serializer: MessageSerializer
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Search messages by body
  def search
    rescue_from Elasticsearch::Transport::Transport::Errors::NotFound do |e|
      render json: { error: "ElasticSearch not found: #{e.message}" }, status: :internal_server_error
    end
    
    if params[:body].present?
      messages = Message.search(params[:body]).records.where(chat_id: @chat.id)
      render json: messages, status: :ok
    else
      render json: { error: 'body parameter is missing' }, status: :bad_request
    end
  end

  
  private

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  end

  def set_chat
    @chat = @application.chats.find_by!(number: params[:chat_number])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
