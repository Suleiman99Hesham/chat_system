class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :chat

  # Custom ElasticSearch index configuration
  settings do
    mappings dynamic: false do
      indexes :body, type: :text, analyzer: 'english'
    end
  end

  # Add a method to reindex data
  def as_indexed_json(_options = {})
    self.as_json(only: %i[body chat_id])
  end
end

# Ensure the ElasticSearch index is created
Message.__elasticsearch__.create_index! force: true
