Refinery::Core::Engine.routes.append do

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
