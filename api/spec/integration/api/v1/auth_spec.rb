require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do
  path '/api/v1/auth/register' do
    post 'Register a new user' do
      tags 'Authentication'
      description 'Create a new user account and receive JWT tokens'
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

      response '201', 'user registered successfully' do
        let(:user) do
          {
            user: {
              username: 'newuser',
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                username: { type: :string },
                email: { type: :string },
                karma_score: { type: :integer },
                created_at: { type: :string, format: 'date-time' }
              }
            },
            access_token: { type: :string },
            refresh_token: { type: :string }
          },
          required: [:user, :access_token, :refresh_token]

        run_test!
      end

      response '422', 'invalid request' do
        let(:user) do
          {
            user: {
              username: 'a',
              email: 'invalid',
              password: '123',
              password_confirmation: '456'
            }
          }
        end

        schema type: :object,
          properties: {
            errors: {
              type: :array,
              items: { type: :string }
            }
          }

        run_test!
      end
    end
  end

  path '/api/v1/auth/login' do
    post 'Login with email and password' do
      tags 'Authentication'
      description 'Authenticate user and receive JWT tokens'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          password: { type: :string }
        },
        required: [:email, :password]
      }

      response '200', 'login successful' do
        let!(:test_user) { create(:user, email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
        let(:credentials) do
          {
            email: 'test@example.com',
            password: 'password123'
          }
        end

        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                username: { type: :string },
                email: { type: :string },
                karma_score: { type: :integer },
                avatar_url: { type: :string, nullable: true },
                is_verified: { type: :boolean }
              }
            },
            access_token: { type: :string },
            refresh_token: { type: :string }
          },
          required: [:user, :access_token, :refresh_token]

        run_test!
      end

      response '401', 'invalid credentials' do
        let(:credentials) do
          {
            email: 'wrong@example.com',
            password: 'wrongpassword'
          }
        end

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end

  path '/api/v1/auth/refresh' do
    post 'Refresh access token' do
      tags 'Authentication'
      description 'Get a new access token using a refresh token'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :token_data, in: :body, schema: {
        type: :object,
        properties: {
          refresh_token: { type: :string }
        },
        required: [:refresh_token]
      }

      response '200', 'token refreshed successfully' do
        let!(:test_user) { create(:user) }
        let(:token_data) do
          {
            refresh_token: JsonWebToken.encode_refresh_token(test_user.id)
          }
        end

        schema type: :object,
          properties: {
            access_token: { type: :string },
            refresh_token: { type: :string }
          },
          required: [:access_token, :refresh_token]

        run_test!
      end

      response '401', 'invalid or expired token' do
        let(:token_data) do
          {
            refresh_token: 'invalid_token'
          }
        end

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end

  path '/api/v1/auth/me' do
    get 'Get current user information' do
      tags 'Authentication'
      description 'Retrieve the authenticated user profile'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'Bearer token'
      security [bearer_auth: []]

      response '200', 'user profile retrieved' do
        let!(:test_user) { create(:user) }
        let(:Authorization) { "Bearer #{JsonWebToken.encode_access_token(test_user.id)}" }

        schema type: :object,
          properties: {
            id: { type: :integer },
            username: { type: :string },
            email: { type: :string },
            karma_score: { type: :integer },
            avatar_url: { type: :string, nullable: true },
            bio: { type: :string, nullable: true },
            website_url: { type: :string, nullable: true },
            is_verified: { type: :boolean },
            created_at: { type: :string, format: 'date-time' },
            followers_count: { type: :integer },
            following_count: { type: :integer }
          }

        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { nil }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end
end
