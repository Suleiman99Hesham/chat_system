class ChatSerializer < ActiveModel::Serializer
  attributes :number, :messages_count, :created_at, :updated_at
  def messages_count
    object.messages_count || 0
  end
end
