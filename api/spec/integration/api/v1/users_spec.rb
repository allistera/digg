require 'swagger_helper'

RSpec.describe 'Users API', type: :request do
  path '/api/v1/users' do
    get 'List users' do
      tags 'Users'
      description 'Retrieve a paginated list of active users sorted by karma score'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'

      response '200', 'users found' do
        schema type: :object,
          properties: {
            users: {
              type: :array,
              items: { '$ref' => '#/components/schemas/User' }
            },
            meta: { '$ref' => '#/components/schemas/PaginationMeta' }
          },
          required: [:users, :meta]

        run_test!
      end
    end

    post 'Create user (register)' do
      tags 'Users'
      description 'Register a new user account'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              username: { type: :string, minLength: 3, maxLength: 30 },
              email: { type: :string, format: :email },
              password: { type: :string, minLength: 6 },
              password_confirmation: { type: :string }
            },
            required: [:username, :email, :password, :password_confirmation]
          }
        },
        required: [:user]
      }

      response '201', 'user created' do
        let(:user) do
          {
            user: {
              username: 'john_doe',
              email: 'john@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        schema type: :object,
          properties: {
            id: { type: :integer },
            username: { type: :string },
            email: { type: :string },
            karma_score: { type: :integer },
            created_at: { type: :string, format: 'date-time' }
          }

        run_test!
      end

      response '422', 'invalid request' do
        let(:user) do
          {
            user: {
              username: 'ab',
              email: 'invalid-email',
              password: '123',
              password_confirmation: '456'
            }
          }
        end

        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'User ID'

    get 'Get user details' do
      tags 'Users'
      description 'Retrieve detailed information about a specific user'
      produces 'application/json'

      response '200', 'user found' do
        schema '$ref' => '#/components/schemas/User'
        let(:id) { 1 }
        run_test!
      end

      response '404', 'user not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 99999 }
        run_test!
      end
    end

    put 'Update user profile' do
      tags 'Users'
      description 'Update user profile information (authentication required)'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              bio: { type: :string },
              website_url: { type: :string, format: :uri },
              avatar_url: { type: :string, format: :uri }
            }
          }
        }
      }

      response '200', 'user updated' do
        let!(:current_user) { create(:user) }
        let(:id) { current_user.id }
        let(:user) do
          {
            user: {
              bio: 'Software developer and tech enthusiast'
            }
          }
        end

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current_user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:user_record) { create(:user) }
        let(:id) { user_record.id }
        let(:user) { { user: { bio: 'New bio' } } }
        run_test!
      end

      response '403', 'forbidden' do
        let!(:current_user) { create(:user) }
        let!(:other_user) { create(:user) }
        let(:id) { other_user.id }
        let(:user) { { user: { bio: 'New bio' } } }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current_user)
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/{id}/articles' do
    parameter name: :id, in: :path, type: :integer, description: 'User ID'

    get "Get user's articles" do
      tags 'Users'
      description 'Retrieve all published articles submitted by a user'
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

        let(:id) { 1 }
        run_test!
      end
    end
  end

  path '/api/v1/users/{id}/followers' do
    parameter name: :id, in: :path, type: :integer, description: 'User ID'

    get "Get user's followers" do
      tags 'Users'
      description 'Retrieve list of users following this user'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'followers found' do
        schema type: :object,
          properties: {
            followers: {
              type: :array,
              items: { '$ref' => '#/components/schemas/User' }
            },
            meta: { '$ref' => '#/components/schemas/PaginationMeta' }
          }

        let(:id) { 1 }
        run_test!
      end
    end
  end
end
