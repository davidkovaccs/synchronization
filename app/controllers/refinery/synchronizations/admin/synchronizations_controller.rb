# -*- encoding : utf-8 -*-
module Refinery
  module Synchronizations
    module Admin
      class SynchronizationsController < ::Refinery::AdminController

        crudify :'refinery/synchronizations/synchronization',
                :title_attribute => 'model_name', :xhr_paging => true

      end
    end
  end
end
