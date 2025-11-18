require 'swagger_helper'

RSpec.describe 'Categories API', type: :request do
  path '/api/v1/categories' do
    get 'List categories' do
      tags 'Categories'
      description 'Retrieve all root categories with their subcategories'
      produces 'application/json'

      response '200', 'categories found' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              slug: { type: :string },
              description: { type: :string },
              display_order: { type: :integer },
              subcategories: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Category' }
              }
            }
          }

        run_test!
      end
    end
  end

  path '/api/v1/categories/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Category ID or slug'

    get 'Get category details' do
      tags 'Categories'
      description 'Retrieve detailed information about a specific category'
      produces 'application/json'

      response '200', 'category found' do
        schema '$ref' => '#/components/schemas/Category'
        let(:id) { 'technology' }
        run_test!
      end

      response '404', 'category not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 'nonexistent' }
        run_test!
      end
    end
  end

  path '/api/v1/categories/{id}/subscribe' do
    parameter name: :id, in: :path, type: :string, description: 'Category ID or slug'

    post 'Subscribe to category' do
      tags 'Categories'
      description 'Subscribe to a category to see its articles in your feed (authentication required)'
      produces 'application/json'
      security [session_auth: []]

      response '200', 'subscribed successfully' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        let!(:user) { create(:user) }
        let!(:category) { create(:category, slug: 'technology') }
        let(:id) { 'technology' }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:category) { create(:category, slug: 'technology') }
        let(:id) { 'technology' }
        run_test!
      end
    end
  end

  path '/api/v1/categories/{id}/unsubscribe' do
    parameter name: :id, in: :path, type: :string, description: 'Category ID or slug'

    delete 'Unsubscribe from category' do
      tags 'Categories'
      description 'Unsubscribe from a category (authentication required)'
      produces 'application/json'
      security [session_auth: []]

      response '200', 'unsubscribed successfully' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        let!(:user) { create(:user) }
        let!(:category) { create(:category, slug: 'technology') }
        let(:id) { 'technology' }

        before do
          # Create subscription first, then unsubscribe
          CategorySubscription.create!(user: user, category: category)
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:category) { create(:category, slug: 'technology') }
        let(:id) { 'technology' }
        run_test!
      end

      response '404', 'not subscribed' do
        let!(:user) { create(:user) }
        let!(:category) { create(:category, slug: 'technology') }
        let(:id) { 'technology' }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end
    end
  end

  path '/api/v1/categories/{id}/articles' do
    parameter name: :id, in: :path, type: :string, description: 'Category ID or slug'

    get 'Get articles in category' do
      tags 'Categories'
      description 'Retrieve all articles in a specific category'
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

        let(:id) { 'technology' }
        run_test!
      end
    end
  end
end
