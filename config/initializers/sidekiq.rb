require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis:6379/0' }

  # Load schedule from sidekiq.yml
  schedule_file = Rails.root.join('config/sidekiq.yml')
  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file)
    if schedule && schedule['scheduler'] && schedule['scheduler']['schedule']
      Sidekiq::Cron::Job.load_from_hash(schedule['scheduler']['schedule'])
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis:6379/0' }
end
