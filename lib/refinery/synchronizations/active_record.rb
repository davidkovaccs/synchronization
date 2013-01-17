module Refinery
  module Paginate
    def paginate(page_num, page_size)
      return self
    end
  end
  Array.send(:include, Paginate)
end

module Refinery
  module Synchronizations
    module ActiveRecord
      module Synchronizable
        $objects_needs_auth = Set.new
        
        def self.included(base)
          base.extend(ClassMethods)
        end
    
        def getModelName
          self.class.name.split("::").last
        end
    
        # synchronization table handling
        def update_synchronization_record_update
          syncObj = Synchronization.where(:model_name => getModelName, :method_name => "update").first
    
          if not syncObj.nil? then
            syncObj.touch
            if syncObj.model_updated_at < self.updated_at then
              syncObj.model_updated_at = self.updated_at
            end
            syncObj.save
          else
            Synchronization.create!(:model_name => getModelName, :method_name => "update", :model_updated_at => self.updated_at)
          end
        end
    
        def update_synchronization_record_delete
          syncObj = Synchronization.where(:model_name => getModelName, :method_name => "delete").first
    
          if (! syncObj.nil?)
            syncObj.touch
            if syncObj.model_updated_at < self.updated_at then
              syncObj.model_updated_at = self.updated_at
            end
            syncObj.save
          else
            Synchronization.create!(:model_name => getModelName, :method_name => "delete", :model_updated_at => self.updated_at)
          end
          
          syncObjUpdate = Synchronization.where(:model_name => getModelName, :method_name => "update").first
          if (! syncObjUpdate.nil? and syncObjUpdate.model_updated_at.eql?(self.updated_at))
            newUpdatedAtObj = self.class.find(:first, :conditions => ["id != ?", self.id], :order => "updated_at DESC")
            if not newUpdatedAtObj.nil? then
              syncObjUpdate.model_updated_at = newUpdatedAtObj.updated_at
              syncObjUpdate.save
            else
              syncObjUpdate.model_updated_at = nil
              syncObjUpdate.save
            end
          end
    
        end
              
        def as_json(options=nil)
          #if (self.include_root_in_json?)
            unless (self.class.json_attrs?.nil?)
              return { getModelName.underscore => Hash[self.class.json_attrs?.map{|j| [j[0],send(j[1])]}] }
            else
              return { getModelName.underscore => attributes }
            end
          #else
          #  unless (self.class.json_attrs?.nil?)
          #    return Hash[self.class.json_attrs?.map{|j| [j[0],send(j[1])]}]
          #  else
          #    return attributes
          #  end
          #end
        end
    
        module ClassMethods
          
          def create_record(params)
            create(params)
          end
          
          def update_record(params)
            Rails.logger.info "Finding record with id: " + params[:id].to_s
            @record = find(params[:id])
            unless @record.nil? then
              Rails.logger.info "record found"
              @record.update_attributes(params)
              @record.save
              return @record
            else
              Rails.logger.info "record not found"
              return nil
            end
          end
    
          def synchronizable(options = {})
            @synchronizable = true
            
            if options[:authenticated] == true
              @needs_authentication = true
            end 

            if needs_authentication?
              $objects_needs_auth << self
            end

            if not options[:methods].nil? and options[:methods].include?(:create) then
              @creatable = true
            end
            
            unless self.eql? Synchronization or needs_authentication? 
              # trigger
              after_save :update_synchronization_record_update
              before_destroy :update_synchronization_record_delete
            end
          end
          
          def creatable?
            return @creatable == true
          end
        
          def synchronizable?
            return @synchronizable == true
          end
          
          def needs_authentication?
            return @needs_authentication == true
          end
          
          def json_attrs(options)
            tmp = options[:fields].map{ |f| [f.to_s, f.to_s] }
            unless options[:mappings].nil?
              options[:mappings].each{|k,v| tmp[tmp.index([k.to_s,k.to_s])][0]=v.to_s}
              @attrs = tmp
            else
              @attrs = tmp
            end
          end
          
          def json_attrs?
            @attrs
          end
        end
      end
    end
  end
end
