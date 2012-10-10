Refinery::Core::Engine.routes.append do

  namespace :synchronizations, :path => '' do
    get "synchronizations/login" => "synchronizations#login"
    post "synchronizations/register_anonymously" => "synchronizations#register_anonymously"
    post "me/verify" => "synchronizations#verify_user"
    post "me/forgot_password" => "synchronizations#forgot_password"
    get "me" => "synchronizations#login"
    post "synchronizations/register" => "synchronizations#register"
    put "me" => "synchronizations#update_user"
  end

  # Frontend routes
  namespace :synchronizations do
    resources :synchronizations, :path => '', :only => [:index, :show]
  end

  # Admin routes
  namespace :synchronizations, :path => '' do
    namespace :admin, :path => 'refinery' do
      resources :synchronizations, :except => :show do
        collection do
          post :update_positions
        end
      end
    end
  end
end
