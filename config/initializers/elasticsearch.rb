Elasticsearch::Model.client = Elasticsearch::Client.new(url: 'elasticsearch:9200')
Rails.application.config.after_initialize do
  if defined?(Message)
    begin
      unless Message.__elasticsearch__.index_exists?
        Message.__elasticsearch__.create_index!
        Rails.logger.info("Elasticsearch index created for Message model.")
      else
        Rails.logger.info("Elasticsearch index already exists for Message model.")
      end
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      Rails.logger.warn("Elasticsearch index creation skipped: #{e.message}")
    end
  end
end

begin
  unless Elasticsearch::Model.client.ping
    Rails.logger.warn("Elasticsearch is not reachable. Indexing will not work until the service is available.")
  end
rescue => e
  Rails.logger.error("Error connecting to Elasticsearch: #{e.message}")
end
