class MessageSerializer < ActiveModel::Serializer
  attributes :number, :body, :created_at, :updated_at
  belongs_to :chat
end
