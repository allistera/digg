# Quick Start Guide

## First Time Setup

### 1. Install Ruby (using rbenv)
```bash
brew install rbenv ruby-build
rbenv install 2.6.10
rbenv local 2.6.10
```

### 2. Install PostgreSQL
```bash
brew install postgresql@14
brew services start postgresql@14
```

### 3. Install Dependencies
```bash
cd api
bundle install
```

### 4. Setup Database
```bash
# Create databases
psql -U postgres -c "CREATE DATABASE digg_development;"
psql -U postgres -c "CREATE DATABASE digg_test;"

# Load schema
psql -U postgres -d digg_development -f ../schema.sql
psql -U postgres -d digg_test -f ../schema.sql
```

### 5. Generate API Documentation
```bash
rake api_docs:generate
```

### 6. Start Server
```bash
bundle exec rails server
```

### 7. Open Documentation in Browser
```bash
open http://localhost:3000/api-docs
```

Or manually open Chrome and navigate to:
```
http://localhost:3000/api-docs
```

## What You'll See

The Swagger UI will display:
- Interactive API documentation
- All endpoints organized by category
- "Try it out" buttons to test each endpoint
- Request/response schemas
- Example values

## Quick Commands

```bash
# Start server
rails s

# Generate docs
rake api_docs:generate

# Run tests
rspec spec/integration

# Open docs
open http://localhost:3000/api-docs

# View API health check
curl http://localhost:3000/health
```

## Troubleshooting

### Server won't start
```bash
# Check if dependencies are installed
bundle check

# Install missing gems
bundle install
```

### Documentation not showing
```bash
# Regenerate docs
rm -rf swagger/v1/swagger.yaml
rake api_docs:generate

# Restart server
```

### Database connection error
```bash
# Check PostgreSQL is running
brew services list

# Start PostgreSQL if needed
brew services start postgresql@14

# Verify connection
psql -U postgres -c "SELECT version();"
```
