require 'swagger_helper'

RSpec.describe 'Comments API', type: :request do
  path '/api/v1/articles/{article_id}/comments' do
    parameter name: :article_id, in: :path, type: :integer, description: 'Article ID'

    get 'List comments for article' do
      tags 'Comments'
      description 'Retrieve root-level comments for an article (nested replies included)'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'comments found' do
        schema type: :object,
          properties: {
            comments: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  content: { type: :string },
                  vote_count: { type: :integer },
                  depth: { type: :integer },
                  created_at: { type: :string, format: 'date-time' },
                  user: { '$ref' => '#/components/schemas/User' },
                  replies: {
                    type: :array,
                    items: { '$ref' => '#/components/schemas/Comment' }
                  }
                }
              }
            },
            meta: { '$ref' => '#/components/schemas/PaginationMeta' }
          }

        let!(:test_article) { create(:article) }
        let(:article_id) { test_article.id }
        run_test!
      end
    end

    post 'Create comment' do
      tags 'Comments'
      description 'Add a comment to an article (authentication required)'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          comment: {
            type: :object,
            properties: {
              content: { type: :string, minLength: 1, maxLength: 10000 }
            },
            required: [:content]
          },
          parent_id: {
            type: :integer,
            description: 'Parent comment ID for replies (optional)'
          }
        },
        required: [:comment]
      }

      response '201', 'comment created' do
        schema '$ref' => '#/components/schemas/Comment'

        let!(:user) { create(:user) }
        let!(:article) { create(:article) }
        let(:article_id) { article.id }
        let(:comment) { { comment: { content: 'Great article! Thanks for sharing.' } } }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:article) { create(:article) }
        let(:article_id) { article.id }
        let(:comment) { { comment: { content: 'Test comment' } } }
        run_test!
      end
    end
  end

  path '/api/v1/comments/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    get 'Get comment details' do
      tags 'Comments'
      description 'Retrieve detailed information about a specific comment'
      produces 'application/json'

      response '200', 'comment found' do
        schema '$ref' => '#/components/schemas/Comment'
        let!(:test_comment) { create(:comment) }
        let(:id) { test_comment.id }
        run_test!
      end

      response '404', 'comment not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 99999 }
        run_test!
      end
    end

    put 'Update comment' do
      tags 'Comments'
      description 'Update a comment (authentication required, owner only)'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          comment: {
            type: :object,
            properties: {
              content: { type: :string }
            },
            required: [:content]
          }
        }
      }

      response '200', 'comment updated' do
        let!(:user) { create(:user) }
        let!(:comment_record) { create(:comment, user: user) }
        let(:id) { comment_record.id }
        let(:comment) { { comment: { content: 'Updated comment text' } } }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:comment_record) { create(:comment) }
        let(:id) { comment_record.id }
        let(:comment) { { comment: { content: 'Updated text' } } }
        run_test!
      end

      response '403', 'forbidden' do
        let!(:user) { create(:user) }
        let!(:other_user) { create(:user) }
        let!(:comment_record) { create(:comment, user: other_user) }
        let(:id) { comment_record.id }
        let(:comment) { { comment: { content: 'Updated text' } } }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end
    end

    delete 'Delete comment' do
      tags 'Comments'
      description 'Soft delete a comment (authentication required, owner only)'
      produces 'application/json'
      security [session_auth: []]

      response '200', 'comment deleted' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        let!(:user) { create(:user) }
        let!(:comment_record) { create(:comment, user: user) }
        let(:id) { comment_record.id }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:comment_record) { create(:comment) }
        let(:id) { comment_record.id }
        run_test!
      end
    end
  end

  path '/api/v1/comments/{id}/vote' do
    parameter name: :id, in: :path, type: :integer, description: 'Comment ID'

    post 'Vote on comment' do
      tags 'Comments'
      description 'Vote on a comment (authentication required). Use vote_type: 1 for upvote, -1 for downvote'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :vote, in: :body, schema: {
        type: :object,
        properties: {
          vote_type: { type: :integer, enum: [-1, 1] }
        },
        required: [:vote_type]
      }

      response '200', 'vote recorded' do
        schema type: :object,
          properties: {
            vote_count: { type: :integer }
          }

        let!(:user) { create(:user) }
        let!(:comment_record) { create(:comment) }
        let(:id) { comment_record.id }
        let(:vote) { { vote_type: 1 } }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end

      response '401', 'unauthorized' do
        let!(:comment_record) { create(:comment) }
        let(:id) { comment_record.id }
        let(:vote) { { vote_type: 1 } }
        run_test!
      end
    end
  end

  path '/api/v1/comments/{id}/comments' do
    parameter name: :id, in: :path, type: :integer, description: 'Parent comment ID'

    post 'Reply to comment' do
      tags 'Comments'
      description 'Add a reply to a comment (authentication required)'
      consumes 'application/json'
      produces 'application/json'
      security [session_auth: []]
      parameter name: :comment, in: :body, schema: {
        type: :object,
        properties: {
          comment: {
            type: :object,
            properties: {
              content: { type: :string }
            },
            required: [:content]
          }
        }
      }

      response '201', 'reply created' do
        schema '$ref' => '#/components/schemas/Comment'

        let!(:user) { create(:user) }
        let!(:parent_comment) { create(:comment) }
        let(:id) { parent_comment.id }
        let(:comment) { { comment: { content: 'Reply to your comment' } } }

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        end

        run_test!
      end
    end
  end
end
