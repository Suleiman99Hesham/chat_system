# Chat System API

This is a backend API for managing applications, chats, and messages, built with Ruby on Rails. It is designed to handle high-concurrency scenarios, ensure sequential numbering of chats and messages, and provide efficient batch processing using Redis and Sidekiq.

## Features

### 1. Applications
- Create applications with a unique token.
- Retrieve, update, and list applications.

### 2. Chats 
- Create chats associated with applications.
- Retrieve chats for specific applications.
- Retrieve a specific chat by its number.
### 3. Messages
- Create messages for specific chats.
- Retrieve messages for specific chats.
- Search messages by body (powered by Elasticsearch).
### 4. Redis Integration
- Redis-backed queuing for chat and message creation.
- Batch processing with background jobs to minimize database writes.
### 5. Elasticsearch Integration
- Full-text search for messages within a chat.
### 6. Background Jobs
- **ProcessChatsJob:** Batch inserts queued chats into the database.
- **ProcessMessagesJob:** Batch inserts queued messages into the database.
- **UpdateCountsJob:** Periodic updates of `chats_count` and `messages_count`.
### 7. Rate Limiting 
- Implemented globally using `Rack::Attack`. Limits requests to 100 per minute per IP.

### 8. Dockerized Deployment
- All services (Rails, Redis, Sidekiq, Elasticsearch, and MySQL) are containerized and can be started with `docker-compose`.

### 9. Redis Backups
- Automated hourly backups of Redis data, with older backups cleaned up daily.

## Installation and Setup

### Prerequisites
- **Docker** and **Docker Compose**
- Ruby (optional, if running locally)

### Steps

1. Clone the repository and Start the application:
    ```bash
   git clone "https://github.com/Suleiman99Hesham/chat_system.git"
   cd chat_system
   docker compose up --build
    ```

2. Run database migrations:
    ```bash
   docker exec app rails db:migrate
   ```
   **Note: If the database does not already exist (e.g., on a fresh setup), you might need to create it first:**
   ```bash
   docker-compose exec app rails db:create
   ```

3. Access the application at http://localhost:3000.

* You can change the following lines in ".env" to control the queue threshold for the chats and messages creation.
    ```
    CHAT_QUEUE_THRESHOLD=10
    MESSAGE_QUEUE_THRESHOLD=10
    ```
* The chats and messages won't be created either until their respective queues have at least batch size items or it lasts for one minute in the queue. The batch is currently 10 to make testing the system easier. 

### Postman Collection
* You can test the system with this [Postman Collection](https://www.postman.com/suleimanhesham99/chat-system-space/collection/71kgxpu/chat-system-api?action=share&creator=9841489)

## API Endpoints

### Applications
- `GET /applications`: List all applications.
- `POST /applications`: Create a new application.
- `GET /applications/:token`: Get details of a specific application.
- `PUT /applications/:token`: Update an application.

### Chats
- `GET /applications/:token/chats`: List all chats for a specific application.
- `POST /applications/:token/chats`: Create a new chat.
- `GET /applications/:token/chats/:number`: Get details of a specific chat.

### Messages
- `GET /applications/:token/chats/:number/messages`: List all messages for a specific chat.
- `POST /applications/:token/chats/:number/messages`: Create a new message.
- `GET /applications/:token/chats/:number/messages/:number`: Get details of a specific message.
- `PUT /applications/:token/chats/:number/messages/:number`: Update a message.
- `GET /applications/:token/chats/:number/messages/search?q=<query>`: Search messages within a chat by body.

## Architecture

### Queueing System
- **Redis** is used to queue chat and message creation requests, minimizing database contention during high-concurrency scenarios.

### Background Jobs
- Jobs are managed with **Sidekiq**, which processes batched inserts for chats and messages.

### Database Design
- **MySQL** is used for persistence, with indexes on `applications`, `chats`, and `messages` for optimal query performance.

### Elasticsearch
- **Elasticsearch** is used for full-text search on message bodies within specific chats.

### Caching
- Frequently accessed data is cached in **Redis** to improve performance.

### Rate Limiting
- `Rack::Attack` middleware limits requests to 100 per minute per IP.

## Environment Variables
|Variable Name|Description|Default Value|
|:-:|:-:|:-:|
|`DATABASE_HOST`|Database host|`db`|
|`DATABASE_USERNAME`|Database username|`root`|
|`DATABASE_PASSWORD`|Database password|`password`|
|`REDIS_URL`|Redis connection URL|`redis://redis:6379/0`|
|`ELASTICSEARCH_URL`|Elasticsearch connection URL|`http://elasticsearch:9200`|


## Monitoring
- **Sidekiq** monitoring is available at `/sidekiq`.

## Future Improvements
- Add specs for all controllers and models.
