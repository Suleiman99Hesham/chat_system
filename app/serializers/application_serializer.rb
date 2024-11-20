class ApplicationSerializer < ActiveModel::Serializer
  attributes :name, :token, :chats_count, :created_at, :updated_at
  def chats_count
    object.chats_count || 0
  end
end
