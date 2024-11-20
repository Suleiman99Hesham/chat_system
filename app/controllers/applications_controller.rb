class ApplicationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Cache Frequently Accessed Data
  def index
    applications = Rails.cache.fetch("applications/index", expires_in: 5.minutes) do
      Application.all.includes(:chats).to_a # Use Preloading for Associations
    end
    render json: applications, each_serializer: ApplicationSerializer, status: :ok # Improve JSON Serialization
  end

  def show
    app = Rails.cache.fetch("applications/#{params[:token]}", expires_in: 5.minutes) do
      Application.includes(:chats).find_by!(token: params[:token]) # Use Preloading for Associations
    end
    render json: app, serializer: ApplicationSerializer, status: :ok # Improve JSON Serialization
  end

  def create
    app = Application.new(application_params)
    app.token = SecureRandom.hex(10)

    if app.save
      # Seed the Redis counter for this application
      REDIS.set("application:#{app.id}:chat_number", app.chats_count || 0)
      render json: { token: app.token }, status: :created
    else
      render json: { errors: app.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    app = Application.find_by!(token: params[:token])
    if app.update(application_params)
      # Invalidate cache after update
      Rails.cache.delete("applications/#{params[:token]}")
      render json: app, serializer: ApplicationSerializer
    else
      render json: { errors: app.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def application_params
    params.require(:application).permit(:name)
  end
end
