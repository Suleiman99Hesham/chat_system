require 'sidekiq/web'

Rails.application.routes.draw do
  resources :applications, param: :token, except: [:destroy] do
    # Fetch all chats for a specific application
    get 'chats', to: 'chats#index'

    resources :chats, param: :number, except: [:destroy, :update] do
      # Fetch all messages for a specific chat
      get 'messages', to: 'messages#index'

      resources :messages, param: :number, except: [:destroy] do
        collection do
          get :search # Search through messages
        end
      end
    end
  end

  # Mount Sidekiq Web UI
  mount Sidekiq::Web => '/sidekiq'
end
