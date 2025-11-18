# Digg Clone REST API

Ruby on Rails API for a Digg-like social news platform.

## Features

- User registration and authentication
- Article submission with voting (upvote/downvote)
- Nested comment system with threading
- Categories and tags for content organization
- User following system
- Category subscriptions
- Personalized feed
- Saved articles
- Content moderation and reporting
- Karma scoring system
- **Interactive OpenAPI/Swagger documentation**

## Prerequisites

- Ruby 2.6+
- PostgreSQL 18+
- Bundler

## Installation

### 1. Install Dependencies

If you encounter permission issues with system Ruby, consider installing a Ruby version manager (rbenv or rvm):

```bash
# Using rbenv (recommended)
brew install rbenv ruby-build
rbenv install 2.6.10
rbenv local 2.6.10

# Install PostgreSQL
brew install postgresql@18
brew services start postgresql@18
```

### 2. Install Gems

```bash
cd api
bundle install
```

### 3. Configure Database

Edit `config/database.yml` or set environment variables:

```bash
export DB_HOST=localhost
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
```

### 4. Setup Database

The database schema is already defined in the parent directory's `schema.sql`. Load it:

```bash
# Create database
psql -U postgres -c "CREATE DATABASE digg_development;"

# Load schema
psql -U postgres -d digg_development -f ../schema.sql

# For test environment
psql -U postgres -c "CREATE DATABASE digg_test;"
psql -U postgres -d digg_test -f ../schema.sql
```

### 5. Start Server

```bash
bundle exec rails server
```

The API will be available at `http://localhost:3000`

## API Documentation

### Interactive Documentation (Recommended)

After starting the server, access the **interactive Swagger UI** at:

```
http://localhost:3000/api-docs
```

Features:
- 🎯 **Try it out** - Test endpoints directly in browser
- 📖 **Complete specs** - All endpoints, parameters, and responses
- 🔍 **Search** - Find endpoints quickly
- 📋 **Copy as cURL** - Get ready-to-use commands
- ✅ **Always up-to-date** - Generated from tests

### Generate Documentation

```bash
# Generate OpenAPI documentation from specs
rake api_docs:generate

# Validate documentation
rake api_docs:validate

# Generate and validate
rake api_docs:all
```

The OpenAPI 3.0 spec is generated at `swagger/v1/swagger.yaml` and can be:
- Imported into Postman, Insomnia, or other API tools
- Used to generate client SDKs
- Validated with online tools

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete documentation guide.

## API Endpoints

### Users
- `GET /api/v1/users` - List users
- `GET /api/v1/users/:id` - Get user details
- `POST /api/v1/users` - Create user (register)
- `PUT /api/v1/users/:id` - Update user profile
- `GET /api/v1/users/:id/articles` - Get user's articles
- `GET /api/v1/users/:id/comments` - Get user's comments
- `GET /api/v1/users/:id/followers` - Get user's followers
- `GET /api/v1/users/:id/following` - Get users being followed

### Articles
- `GET /api/v1/articles` - List articles (supports filtering and sorting)
- `GET /api/v1/articles/:id` - Get article details
- `POST /api/v1/articles` - Submit article
- `PUT /api/v1/articles/:id` - Update article
- `DELETE /api/v1/articles/:id` - Delete article
- `POST /api/v1/articles/:id/vote` - Vote on article
- `DELETE /api/v1/articles/:id/unvote` - Remove vote
- `GET /api/v1/trending` - Get trending articles
- `GET /api/v1/hot` - Get hot articles

### Comments
- `GET /api/v1/articles/:article_id/comments` - List comments for article
- `POST /api/v1/articles/:article_id/comments` - Create comment
- `GET /api/v1/comments/:id` - Get comment details
- `PUT /api/v1/comments/:id` - Update comment
- `DELETE /api/v1/comments/:id` - Delete comment (soft delete)
- `POST /api/v1/comments/:id/vote` - Vote on comment
- `DELETE /api/v1/comments/:id/unvote` - Remove vote
- `POST /api/v1/comments/:id/comments` - Reply to comment

### Categories
- `GET /api/v1/categories` - List categories
- `GET /api/v1/categories/:id` - Get category details
- `POST /api/v1/categories/:id/subscribe` - Subscribe to category
- `DELETE /api/v1/categories/:id/unsubscribe` - Unsubscribe from category
- `GET /api/v1/categories/:id/articles` - Get articles in category

### Tags
- `GET /api/v1/tags` - List tags
- `GET /api/v1/tags/:id` - Get tag details
- `GET /api/v1/tags/:id/articles` - Get articles with tag

### Saved Articles
- `GET /api/v1/saved_articles` - List saved articles
- `POST /api/v1/saved_articles` - Save article
- `DELETE /api/v1/saved_articles/:id` - Remove saved article

### Reports
- `GET /api/v1/reports` - List reports
- `POST /api/v1/reports` - Submit report

### Feed
- `GET /api/v1/feed` - Get personalized feed

### Health Check
- `GET /health` - Health check endpoint

## Query Parameters

### Pagination
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 20)

### Sorting Articles
- `sort=recent` - Sort by creation date
- `sort=hot` - Sort by hotness score
- `sort=votes` - Sort by vote count

### Filtering
- `category_id` - Filter by category
- `user_id` - Filter by user
- `tag_id` - Filter by tag

## Request Examples

### Register User
```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "username": "john_doe",
      "email": "john@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

### Submit Article
```bash
curl -X POST http://localhost:3000/api/v1/articles \
  -H "Content-Type: application/json" \
  -d '{
    "article": {
      "title": "Interesting Article Title",
      "url": "https://example.com/article",
      "description": "Brief description of the article",
      "category_id": 1
    },
    "tags": ["technology", "programming"]
  }'
```

### Vote on Article
```bash
curl -X POST http://localhost:3000/api/v1/articles/1/vote \
  -H "Content-Type: application/json" \
  -d '{"vote_type": 1}'
```

### Create Comment
```bash
curl -X POST http://localhost:3000/api/v1/articles/1/comments \
  -H "Content-Type: application/json" \
  -d '{
    "comment": {
      "content": "Great article!"
    }
  }'
```

## Response Format

All responses follow a consistent JSON format:

### Success Response
```json
{
  "articles": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100
  }
}
```

### Error Response
```json
{
  "error": "Error message",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

## Authentication

Currently, the API uses session-based authentication. For production use, implement:
- JWT tokens
- OAuth2
- API keys

## CORS Configuration

CORS is configured to allow all origins in development. Update `config/application.rb` for production:

```ruby
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'yourdomain.com'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

## Project Structure

```
api/
├── app/
│   ├── controllers/
│   │   ├── api/v1/          # API controllers
│   │   └── application_controller.rb
│   └── models/              # ActiveRecord models
├── config/
│   ├── environments/        # Environment configs
│   ├── initializers/        # Initializers
│   ├── application.rb       # App configuration
│   ├── boot.rb
│   ├── database.yml         # Database config
│   ├── environment.rb
│   └── routes.rb            # API routes
├── db/                      # Database files
├── Gemfile                  # Ruby dependencies
└── config.ru               # Rack config
```

## Development

### Running Tests
```bash
bundle exec rspec
```

### Console
```bash
bundle exec rails console
```

### Database Console
```bash
psql -U postgres -d digg_development
```

## Next Steps

1. **Install Ruby/PostgreSQL** - Set up the required dependencies
2. **Authentication** - Implement JWT-based authentication
3. **Pagination Gem** - Add `kaminari` or `pagy` for pagination support
4. **Serializers** - Add `active_model_serializers` or `jsonapi-serializer`
5. **Testing** - Set up RSpec with FactoryBot
6. **Background Jobs** - Configure Sidekiq for async tasks (karma calculation, hotness score updates)
7. **Caching** - Implement Redis caching for hot articles and feeds
8. **Rate Limiting** - Add `rack-attack` for API rate limiting
9. **Documentation** - Add Swagger/OpenAPI documentation
10. **Monitoring** - Set up error tracking (Sentry) and performance monitoring

## Notes

- Models include validations and associations matching the database schema
- Denormalized counters (vote_count, comment_count) are automatically updated
- Comments use materialized path for efficient tree traversal
- Hotness score calculation for ranking algorithms
- Karma system tracks user reputation through activities
- Soft deletion for comments preserves conversation context

## License

MIT
