require 'swagger_helper'

RSpec.describe 'Articles API', type: :request do
  path '/api/v1/articles' do
    get 'List articles' do
      tags 'Articles'
      description 'Retrieve a paginated list of published articles with filtering and sorting options'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: :sort, in: :query, type: :string, required: false, description: 'Sort order', schema: { type: :string, enum: ['recent', 'hot', 'votes'] }
      parameter name: :category_id, in: :query, type: :integer, required: false, description: 'Filter by category'
      parameter name: :user_id, in: :query, type: :integer, required: false, description: 'Filter by user'
      parameter name: :tag_id, in: :query, type: :integer, required: false, description: 'Filter by tag'

      response '200', 'articles found' do
        schema type: :object,
          properties: {
            articles: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  title: { type: :string },
                  url: { type: :string },
                  description: { type: :string },
                  vote_count: { type: :integer },
                  comment_count: { type: :integer },
                  view_count: { type: :integer },
                  created_at: { type: :string, format: 'date-time' },
                  user: { '$ref' => '#/components/schemas/User' },
                  category: { '$ref' => '#/components/schemas/Category' },
                  tags: {
                    type: :array,
                    items: { '$ref' => '#/components/schemas/Tag' }
                  }
                }
              }
            },
            meta: { '$ref' => '#/components/schemas/PaginationMeta' }
          }

        run_test!
      end
    end

    post 'Submit article' do
      tags 'Articles'
      description 'Submit a new article (authentication required)'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :article, in: :body, schema: {
        type: :object,
        properties: {
          article: {
            type: :object,
            properties: {
              title: { type: :string, minLength: 10, maxLength: 200 },
              url: { type: :string, format: :uri },
              description: { type: :string },
              thumbnail_url: { type: :string, format: :uri },
              category_id: { type: :integer }
            },
            required: [:title, :url, :category_id]
          },
          tags: {
            type: :array,
            items: { type: :string },
            description: 'Array of tag names'
          }
        },
        required: [:article]
      }

      response '201', 'article created' do
        let(:article) do
          {
            article: {
              title: 'Interesting Article About Technology',
              url: 'https://example.com/article',
              description: 'A comprehensive guide to modern technology',
              category_id: 1
            },
            tags: ['technology', 'programming']
          }
        end

        schema '$ref' => '#/components/schemas/Article'
        run_test!
      end

      response '401', 'unauthorized' do
        let(:article) { { article: { title: 'Test', url: 'https://example.com', category_id: 1 } } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:article) { { article: { title: 'Short', url: 'invalid-url' } } }
        run_test!
      end
    end
  end

  path '/api/v1/articles/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    get 'Get article details' do
      tags 'Articles'
      description 'Retrieve detailed information about a specific article'
      produces 'application/json'

      response '200', 'article found' do
        schema '$ref' => '#/components/schemas/Article'
        let(:id) { 1 }
        run_test!
      end

      response '404', 'article not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 99999 }
        run_test!
      end
    end

    delete 'Delete article' do
      tags 'Articles'
      description 'Delete an article (authentication required, owner only)'
      produces 'application/json'
      security [session_auth: []]

      response '204', 'article deleted' do
        let(:id) { 1 }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:id) { 1 }
        run_test!
      end

      response '403', 'forbidden' do
        let(:id) { 2 }
        run_test!
      end
    end
  end

  path '/api/v1/articles/{id}/vote' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    post 'Vote on article' do
      tags 'Articles'
      description 'Vote on an article (authentication required). Use vote_type: 1 for upvote, -1 for downvote'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :vote, in: :body, schema: {
        type: :object,
        properties: {
          vote_type: { type: :integer, enum: [-1, 1], description: '1 for upvote, -1 for downvote' }
        },
        required: [:vote_type]
      }

      response '200', 'vote recorded' do
        schema type: :object,
          properties: {
            vote_count: { type: :integer }
          }

        let(:id) { 1 }
        let(:vote) { { vote_type: 1 } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:id) { 1 }
        let(:vote) { { vote_type: 1 } }
        run_test!
      end

      response '400', 'invalid vote type' do
        let(:id) { 1 }
        let(:vote) { { vote_type: 5 } }
        run_test!
      end
    end
  end

  path '/api/v1/articles/{id}/unvote' do
    parameter name: :id, in: :path, type: :integer, description: 'Article ID'

    delete 'Remove vote from article' do
      tags 'Articles'
      description 'Remove your vote from an article (authentication required)'
      produces 'application/json'
      security [session_auth: []]

      response '200', 'vote removed' do
        schema type: :object,
          properties: {
            vote_count: { type: :integer }
          }

        let(:id) { 1 }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/trending' do
    get 'Get trending articles' do
      tags 'Articles'
      description 'Retrieve articles trending in the last 24 hours'
      produces 'application/json'

      response '200', 'trending articles found' do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/Article' }

        run_test!
      end
    end
  end

  path '/api/v1/hot' do
    get 'Get hot articles' do
      tags 'Articles'
      description 'Retrieve hot articles ranked by hotness score'
      produces 'application/json'

      response '200', 'hot articles found' do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/Article' }

        run_test!
      end
    end
  end
end
