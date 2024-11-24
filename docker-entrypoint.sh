#!/bin/bash
set -e

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch..."
until curl -s http://elasticsearch:9200/_cat/health > /dev/null; do
  echo "Elasticsearch is not available yet, retrying in 5 seconds..."
  sleep 5
done

echo "Elasticsearch is up and running!"

# Ensure Elasticsearch index exists
echo "Checking Elasticsearch index..."
bundle exec rails runner "
  unless Message.__elasticsearch__.index_exists?
    Message.__elasticsearch__.create_index!
  else
    puts 'Index already exists, skipping creation.'
  end
"

# Reindex data if necessary
echo "Reindexing Elasticsearch data..."
bundle exec rails runner "
  Message.find_each do |message|
    message.__elasticsearch__.index_document
  end
"

# Proceed with the default entrypoint
exec "$@"
