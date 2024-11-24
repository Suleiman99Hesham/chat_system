class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :chat

  # Custom ElasticSearch index configuration
  settings index: { number_of_shards: 1 } do
    mappings dynamic: false do
      indexes :body, type: :text
    end
  end

  # Add a method to reindex data
  def as_indexed_json(_options = {})
    self.as_json(only: [:body, :chat_id])
  end
end

# Ensure the ElasticSearch index is created
if !Message.__elasticsearch__.index_exists?
  Message.__elasticsearch__.create_index!
else
  Rails.logger.info("Index already exists, skipping creation.")
end

