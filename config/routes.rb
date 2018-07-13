Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/mine', as: 'rails_admin'
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    get '/users/auth/kakao', to: 'users/omniauth_callbacks#kakao'  # 클릭하면 대신 요청을 보냄
    get '/users/auth/kakao/callback', to: 'users/omniauth_callbacks#kakao_auth'    # callback을 받는 친구
  end

  root 'movies#index'
  resources :movies do
    member do    # id까지 포함
      post '/comments' => 'movies#create_comment'
    end
    collection do
      delete '/comments/:comment_id' => 'movies#destroy_comment'
      patch '/comments/:comment_id' => 'movies#update_comment'
      get '/search_movie' => 'movies#search_movie'
    end
    # collection do
    #   get '/test' => 'movies#test_collection'
    # end
  end
  
  post '/uploads' => 'movies#upload_image'
  
  get '/likes/:movie_id' => 'movies#like_movie'
 # post '/movies/:movie_id/comments' => 'movies#comments'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
