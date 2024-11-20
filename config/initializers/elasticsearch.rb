Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: 'http://elasticsearch:9200',
  transport_options: {
    request: { timeout: 5 }
  }
)
