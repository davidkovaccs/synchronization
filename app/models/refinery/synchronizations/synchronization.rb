module Refinery
  module Synchronizations
    class Synchronization < Refinery::Core::BaseModel
      self.table_name = 'refinery_synchronizations'      
    
      synchronizable
      json_attrs :fields => [:id, :model_name, :method_name, :model_updated_at, :updated_at]
    
      acts_as_indexed :fields => [:model_name, :method_name]

      attr_accessible :model_name, :method_name, :model_updated_at, :position, :updated_at
    
      validates :model_name, :presence => true
      validates :method_name, :presence => true
      validates :model_updated_at, :presence => true

    end
  end
end
