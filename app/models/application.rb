class Application < ApplicationRecord
  has_many :chats, dependent: :destroy
end

