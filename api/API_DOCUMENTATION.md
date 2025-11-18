# API Documentation Guide

This project uses **RSwag** to generate interactive OpenAPI/Swagger documentation directly from RSpec tests.

## Overview

The API documentation system provides:
- **Interactive Swagger UI** for testing endpoints
- **OpenAPI 3.0 specification** (machine-readable)
- **Auto-generated from tests** (always in sync with code)
- **Try it out** feature for live API testing

## Quick Start

### 1. Install Dependencies

```bash
bundle install
```

### 2. Generate Documentation

```bash
# Generate OpenAPI docs from RSpec specs
rake api_docs:generate

# Or run RSpec directly
SWAGGER_DRY_RUN=0 bundle exec rspec spec/integration --format Rswag::Specs::SwaggerFormatter --order defined
```

### 3. View Documentation

Start the Rails server:
```bash
bundle exec rails server
```

Access the Swagger UI at:
```
http://localhost:3000/api-docs
```

## Documentation Structure

```
api/
├── spec/
│   ├── swagger_helper.rb          # OpenAPI base configuration
│   ├── integration/
│   │   └── api/v1/
│   │       ├── users_spec.rb      # Users API specs
│   │       ├── articles_spec.rb   # Articles API specs
│   │       ├── comments_spec.rb   # Comments API specs
│   │       └── categories_spec.rb # Categories API specs
│   └── rails_helper.rb
├── swagger/
│   └── v1/
│       └── swagger.yaml           # Generated OpenAPI spec
└── config/
    └── initializers/
        ├── rswag_api.rb           # RSwag API config
        └── rswag_ui.rb            # Swagger UI config
```

## Writing API Specs

API specs serve dual purposes:
1. **Test the API** (RSpec integration tests)
2. **Generate documentation** (OpenAPI spec)

### Example Spec

```ruby
require 'swagger_helper'

RSpec.describe 'Articles API', type: :request do
  path '/api/v1/articles' do
    get 'List articles' do
      tags 'Articles'
      description 'Retrieve a paginated list of published articles'
      produces 'application/json'

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'articles found' do
        schema type: :object,
          properties: {
            articles: {
              type: :array,
              items: { '$ref' => '#/components/schemas/Article' }
            },
            meta: { '$ref' => '#/components/schemas/PaginationMeta' }
          }

        run_test!  # This actually runs the test
      end
    end
  end
end
```

## Key Components

### 1. swagger_helper.rb

Defines the base OpenAPI specification:
- API metadata (title, version, description)
- Server URLs
- Reusable schemas (User, Article, Comment, etc.)
- Security schemes
- Common responses

### 2. Integration Specs

Located in `spec/integration/api/v1/`:
- Define endpoints and their behavior
- Specify request/response schemas
- Include examples and descriptions
- Run actual tests to validate API

### 3. Generated Documentation

After running specs, OpenAPI YAML is generated at:
```
swagger/v1/swagger.yaml
```

This file:
- Is machine-readable (OpenAPI 3.0 format)
- Powers the Swagger UI
- Can be used to generate client SDKs
- Can be imported into API tools (Postman, Insomnia)

## Common Tasks

### Generate Documentation

```bash
# Generate from specs
rake api_docs:generate

# Validate generated YAML
rake api_docs:validate

# Generate and validate
rake api_docs:all
```

### Run Tests Only (without generating docs)

```bash
bundle exec rspec spec/integration
```

### Update Documentation

1. Modify the spec file in `spec/integration/api/v1/`
2. Run `rake api_docs:generate`
3. Refresh browser at `/api-docs`

### Add New Endpoint Documentation

1. Create or update spec file in `spec/integration/api/v1/`
2. Follow the RSwag DSL pattern:
   ```ruby
   path '/api/v1/new-endpoint' do
     get 'Description' do
       tags 'TagName'
       produces 'application/json'

       response '200', 'success' do
         schema type: :object, properties: { ... }
         run_test!
       end
     end
   end
   ```
3. Generate docs: `rake api_docs:generate`

## Swagger UI Features

The interactive documentation includes:

### Try It Out
- Click "Try it out" on any endpoint
- Fill in parameters
- Click "Execute" to make a real API call
- See the response

### Request/Response Examples
- View example requests
- See expected response formats
- Copy curl commands

### Schema Validation
- See required vs optional fields
- View data types and formats
- Understand nested objects

### Authentication
- Test authenticated endpoints
- See security requirements
- Understand auth flow

## Customization

### Update API Metadata

Edit `spec/swagger_helper.rb`:

```ruby
config.swagger_docs = {
  'v1/swagger.yaml' => {
    info: {
      title: 'Your API Title',
      version: 'v1',
      description: 'Your description',
      contact: { ... },
      license: { ... }
    },
    servers: [
      { url: 'https://your-api.com', description: 'Production' }
    ]
  }
}
```

### Add Reusable Schemas

In `swagger_helper.rb` under `components.schemas`:

```ruby
YourModel: {
  type: :object,
  properties: {
    id: { type: :integer },
    name: { type: :string }
  },
  required: [:id, :name]
}
```

Reference in specs:
```ruby
schema '$ref' => '#/components/schemas/YourModel'
```

### Configure Swagger UI

Edit `config/initializers/rswag_ui.rb`:

```ruby
Rswag::Ui.configure do |c|
  c.config_object = {
    deepLinking: true,
    displayRequestDuration: true,
    docExpansion: 'list',  # 'none', 'list', or 'full'
    filter: true,
    showExtensions: true,
    tryItOutEnabled: true
  }
end
```

## Best Practices

### 1. Keep Tests and Docs in Sync
- Run `rake api_docs:generate` after spec changes
- Include `run_test!` to validate examples
- Use realistic test data

### 2. Provide Clear Descriptions
```ruby
get 'List articles' do
  description 'Retrieve a paginated list of published articles with filtering options'
  # More detailed than just "List articles"
end
```

### 3. Document All Parameters
```ruby
parameter name: :page,
          in: :query,
          type: :integer,
          required: false,
          description: 'Page number (default: 1)'
```

### 4. Include All Response Codes
```ruby
response '200', 'success' do ... end
response '401', 'unauthorized' do ... end
response '404', 'not found' do ... end
response '422', 'validation error' do ... end
```

### 5. Use Schema References
Avoid duplicating schemas:
```ruby
# Good
schema '$ref' => '#/components/schemas/User'

# Avoid
schema type: :object, properties: { id: ..., username: ..., ... }
```

### 6. Tag Endpoints Logically
Group related endpoints:
```ruby
tags 'Users'     # All user-related endpoints
tags 'Articles'  # All article-related endpoints
```

## Exporting Documentation

### Download OpenAPI Spec
```bash
# YAML format
curl http://localhost:3000/api-docs/v1/swagger.yaml > openapi.yaml

# JSON format (if configured)
curl http://localhost:3000/api-docs/v1/swagger.json > openapi.json
```

### Generate Client SDKs

Use tools like:
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Swagger Codegen](https://swagger.io/tools/swagger-codegen/)

```bash
# Example: Generate TypeScript client
openapi-generator-cli generate \
  -i http://localhost:3000/api-docs/v1/swagger.yaml \
  -g typescript-axios \
  -o ./clients/typescript
```

### Import to API Tools

Import the OpenAPI spec into:
- **Postman**: File → Import → Paste URL or file
- **Insomnia**: Create → Import → From URL
- **Stoplight Studio**: Import OpenAPI file
- **API Blueprint**: Convert using tools

## Troubleshooting

### Documentation not updating
```bash
# Clear generated files
rm -rf swagger/v1/swagger.yaml

# Regenerate
rake api_docs:generate
```

### Swagger UI not loading
- Check Rails logs for errors
- Verify routes: `rails routes | grep rswag`
- Ensure initializers are loaded

### Invalid OpenAPI spec
```bash
# Validate YAML syntax
rake api_docs:validate

# Use online validator
# Upload swagger.yaml to https://editor.swagger.io
```

### Tests failing
```bash
# Run individual spec
bundle exec rspec spec/integration/api/v1/users_spec.rb

# Debug with verbose output
bundle exec rspec spec/integration/api/v1/users_spec.rb --format documentation
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: API Documentation

on: [push, pull_request]

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 2.6
      - name: Install dependencies
        run: bundle install
      - name: Generate API docs
        run: rake api_docs:generate
      - name: Validate docs
        run: rake api_docs:validate
      - name: Upload artifact
        uses: actions/upload-artifact@v2
        with:
          name: openapi-spec
          path: swagger/v1/swagger.yaml
```

## Additional Resources

- [RSwag Documentation](https://github.com/rswag/rswag)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Swagger UI Configuration](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/)
- [OpenAPI Best Practices](https://swagger.io/resources/articles/best-practices-in-api-documentation/)

## Summary

The RSwag approach provides:
- ✅ **Single source of truth** - Tests = Documentation
- ✅ **Always up-to-date** - Generated from actual code
- ✅ **Interactive** - Try endpoints in browser
- ✅ **Standard format** - OpenAPI 3.0
- ✅ **Developer-friendly** - Write once, test and document
- ✅ **Client SDK generation** - Auto-generate API clients
- ✅ **Version control** - Track changes in git

This approach is superior to manual documentation because:
1. Documentation can't drift from implementation
2. Changes to API automatically update docs
3. Validates API behavior through tests
4. Provides interactive playground for developers
