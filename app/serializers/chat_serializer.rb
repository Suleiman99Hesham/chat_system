class ChatSerializer < ActiveModel::Serializer
  attributes :number, :messages_count, :created_at, :updated_at
  belongs_to :application
  has_many :messages
end
