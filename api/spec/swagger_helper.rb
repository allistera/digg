require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Digg Clone API',
        version: 'v1',
        description: 'REST API for a Digg-like social news platform',
        contact: {
          name: 'API Support',
          url: 'https://github.com/yourusername/digg-api'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://api.example.com',
          description: 'Production server'
        }
      ],
      components: {
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              username: { type: :string },
              email: { type: :string, format: :email },
              karma_score: { type: :integer },
              avatar_url: { type: :string, nullable: true },
              bio: { type: :string, nullable: true },
              website_url: { type: :string, nullable: true },
              is_verified: { type: :boolean },
              created_at: { type: :string, format: 'date-time' }
            },
            required: [:id, :username, :email]
          },
          Article: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              url: { type: :string, format: :uri },
              description: { type: :string, nullable: true },
              thumbnail_url: { type: :string, nullable: true },
              domain: { type: :string, nullable: true },
              vote_count: { type: :integer },
              comment_count: { type: :integer },
              view_count: { type: :integer },
              hotness_score: { type: :number, format: :float },
              status: { type: :string, enum: [:pending, :approved, :published] },
              created_at: { type: :string, format: 'date-time' }
            },
            required: [:id, :title, :url]
          },
          Comment: {
            type: :object,
            properties: {
              id: { type: :integer },
              content: { type: :string },
              vote_count: { type: :integer },
              depth: { type: :integer },
              parent_id: { type: :integer, nullable: true },
              is_deleted: { type: :boolean },
              created_at: { type: :string, format: 'date-time' }
            },
            required: [:id, :content]
          },
          Category: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              slug: { type: :string },
              description: { type: :string, nullable: true },
              display_order: { type: :integer },
              parent_id: { type: :integer, nullable: true }
            },
            required: [:id, :name, :slug]
          },
          Tag: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              slug: { type: :string },
              usage_count: { type: :integer }
            },
            required: [:id, :name, :slug]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string },
              errors: {
                type: :array,
                items: { type: :string }
              }
            }
          },
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer }
            }
          }
        },
        securitySchemes: {
          session_auth: {
            type: :apiKey,
            name: :_session_id,
            in: :cookie,
            description: 'Session-based authentication'
          }
        }
      }
    }
  }

  config.swagger_format = :yaml
end
