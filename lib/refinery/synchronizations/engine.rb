module Refinery
  module Synchronizations
    require 'refinery/synchronizations/railtie'

    class Engine < Rails::Engine
      include Refinery::Engine
      isolate_namespace Refinery::Synchronizations

      engine_name :refinery_synchronizations

      initializer "register refinerycms_synchronizations plugin" do
        Refinery::Plugin.register do |plugin|
          plugin.name = "synchronizations"
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.synchronizations_admin_synchronizations_path }
          plugin.pathname = root
          plugin.hide_from_menu = true
          plugin.activity = {
            :class_name => :'refinery/synchronizations/synchronization',
            :title => 'model_name'
          }
          
        end
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::Synchronizations)
      end
    end
  end
end
