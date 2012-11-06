require 'rails'

module Refinery
  module Synchronizations
    class Railtie < Rails::Railtie

      initializer 'refinerycms-synchronizations' do |app|

      ActiveSupport.on_load(:active_record) do
        require 'refinery/synchronizations/active_record'
        ::ActiveRecord::Base.send(:include, ActiveRecord::Synchronizable)
      end
        
      Refinery::Core::Engine.routes.prepend do
        #authenticated do
        #  get "synchronizations.(:format)", :to => "Synchronizations::Synchronizations#synchronizations_all_auth"
        #end
        get "synchronizations.(:format)", :to => "Synchronizations::Synchronizations#synchronizations_all"
      end
        
        Refinery::Core::Engine.routes.prepend do
          class ModelHasCreateMethod
            def self.matches?(request)
              return (not ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).nil? and
                          ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).synchronizable? and
                          ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).creatable?)
            end
          end
          post ":model_name", :to => "Synchronizations::Synchronizations#create_record", :constraints => ModelHasCreateMethod
        end
      
        Refinery::Core::Engine.routes.prepend do
          class SynchronizableAndNeedsAuthentication
            def self.matches?(request)
              return (not ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).nil? and
                          ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).synchronizable? and
                          ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).needs_authentication?)
            end
          end
          get ":model_name.(:format)", :to => "Synchronizations::Synchronizations#sync_model_auth", :constraints => SynchronizableAndNeedsAuthentication
          get ":model_name/indexes.(:format)", :to => "Synchronizations::Synchronizations#model_indexes_auth", :constraints => SynchronizableAndNeedsAuthentication
        end
        
        Refinery::Core::Engine.routes.prepend do
          class Synchronizable
            def self.matches?(request)
              return (not ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).nil? and
                      ::Refinery::Synchronizations::SynchronizationsController.get_model(request.params[:model_name]).synchronizable?)
            end
          end
          
          get ":model_name.(:format)", :to => "Synchronizations::Synchronizations#sync_model", :constraints => Synchronizable
          get ":model_name/indexes.(:format)", :to => "Synchronizations::Synchronizations#model_indexes", :constraints => Synchronizable
        end

      end

    end
  end
end
