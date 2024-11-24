FROM ruby:2.7.2

# Install system dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs redis

# Upgrade RubyGems and install Bundler
RUN gem update --system 3.3.22
RUN gem install bundler -v 2.4.22

# Set up the app directory
WORKDIR /app

# Copy the Gemfile and install gems
COPY Gemfile Gemfile.lock /app/
RUN bundle install

# Copy the rest of the application
COPY . /app

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["rails", "server", "-b", "0.0.0.0"]
