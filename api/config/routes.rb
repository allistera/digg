Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show, :create, :update] do
        member do
          get :articles
          get :comments
          get :followers
          get :following
        end
      end

      resources :articles do
        member do
          post :vote
          delete :unvote
        end
        resources :comments, only: [:index, :create]
      end

      resources :comments, only: [:show, :update, :destroy] do
        member do
          post :vote
          delete :unvote
        end
        resources :comments, only: [:create]
      end

      resources :categories do
        member do
          post :subscribe
          delete :unsubscribe
        end
        resources :articles, only: [:index]
      end

      resources :tags, only: [:index, :show] do
        resources :articles, only: [:index]
      end

      resources :saved_articles, only: [:index, :create, :destroy]
      resources :reports, only: [:create, :index]

      get 'feed', to: 'feed#index'
      get 'trending', to: 'articles#trending'
      get 'hot', to: 'articles#hot'
    end
  end

  get '/health', to: proc { [200, {}, ['OK']] }
end
