require 'devise'
module Refinery
  module Synchronizations
    class SynchronizationsController < ::ApplicationController
     
      before_filter :check_model, :only => [:sync_model, :sync_model_auth, :create_record, :create_record_auth, :model_indexes, :model_indexes_auth]
      before_filter :require_authentication, :only => [:sync_model_auth, :create_record_auth, :model_indexes_auth]
      before_filter :check_authentication, :only => [:synchronizations_all]
    
      rescue_from ::BadRequest, :with => :bad_request
      rescue_from ::RecordConflict, :with => :record_conflict
      rescue_from ::Forbidden, :with => :forbidden
      rescue_from ::Unauthorized, :with => :unauthorized

      # FIXME: is this necessary?
      def devise_controller?
        true
      end

      def index
        # you can use meta fields from your model instead (e.g. browser_title)
        # by swapping @page for @synchronization in the line below:
        present(@page)
      end

      def show
        @synchronization = Synchronization.find(params[:id])

        # you can use meta fields from your model instead (e.g. browser_title)
        # by swapping @page for @synchronization in the line below:
        present(@page)
      end
      
      def model_indexes
        if @model.needs_authentication? then
          # FIXME: should never happen
          return "Internal Server Error"
        end
        
        if params[:updated_at].nil? then
          @records = @model.all(:select => "id").collect(&:id)
        end
        
        respond_with_records @records    
      end
      
      def model_indexes_auth
          if current_user.nil? then
            # FIXME: should never happen
            return render :json => "", :status => 401
          end
  
          if params[:updated_at].nil? then
            @records = @model.find_all_by_user_id(current_user.id).collect(&:id)
          end
          
          return respond_with_records @records
      end
  
      # ------------------------------
      # custom synchronization methods
      # FIXME: +1
      def sync_model_auth
          if current_user.nil? then
            # FIXME: should never happen
            return render :json => "", :status => 401
          end

          Rails.logger.info "Current user: #{current_user.id.to_s} #{current_user.first_name}"

          if params[:updated_at].nil? then
            @records = @model.find_all_by_user_id(current_user.id)
          else
            @records = @model.find_all_by_user_id(current_user.id).select { |ar| ar.updated_at > Time.parse(params[:updated_at])+1}
          end
          
          return respond_with_records @records
      end
  
      # FIXME: +1
      # update sync a whole model
      def sync_model
        if @model.needs_authentication? then
          # FIXME: should never happen
          return "Internal Server Error"
        end
        
        if params[:updated_at].nil? then
          @records = @model.all
        else
          @records = @model.find(:all, :conditions => ['updated_at > ?', Time.parse(params[:updated_at])+1])
        end
        
        respond_with_records @records    
      end
      
      # FIXME: +1
      def synchronizations_all_auth
        if params[:updated_at].nil? then
          @records = Synchronization.all
        else
          @records = Synchronization.find(:all, :conditions => ['updated_at > ?', Time.parse(params[:updated_at])+1])
        end
        
        ::Refinery::Runs::Run.first
        ::Refinery::CouponItems::CouponItem.first

        for obj_class in $objects_needs_auth do
          Rails.logger.info "Obj that needs auth: #{obj_class.name}"
          obj = nil
          if params[:updated_at].nil? then
            obj = obj_class.find_all_by_user_id(current_user.id).sort_by(&:updated_at).last
          else
            obj = obj_class.find_all_by_user_id(current_user.id).select(&:updated_at > Time.parse(params[:updated_at])+1).sort_by(&:updated_at).last
            #obj = obj_class.find(:first, :order => "updated_at DESC", :conditions => ['updated_at > ? and user_id = ?', Time.parse(params[:updated_at])+1, current_user.id])
          end
          
          unless obj.nil? then
             new_rec = Synchronization.new(:method_name => "update", :model_name => obj_class.name.split('::').last, :model_updated_at => obj.updated_at, :updated_at => obj.updated_at)
             new_rec.id = generate_model_id(obj_class.name, current_user.id, true)
             @records << new_rec
          end
        end

        respond_with_records @records    
      end
      
      def generate_model_id(obj_class_name, user_id, update)
        if (update) then
          gen_id = "#{user_id}440000"
        else
          gen_id = "#{user_id}990000"
        end

        gen_id = gen_id.to_i
        Rails.logger.info "gen0 id: #{gen_id}"
        obj_class_name.bytes.each do |c|
          gen_id = gen_id + c
        end
        Rails.logger.info "gen1 id: #{gen_id}"
        gen_id
        return gen_id.to_s
      end
      
      # FIXME: +1
      def synchronizations_all
        unless current_user.nil?
          Rails.logger.info "User is authenticated! User id: #{current_user.id}"
          return synchronizations_all_auth
        end
        Rails.logger.info "User is NOT authenticated!"

        if params[:updated_at].nil? then
          @records = Synchronization.all
        else
          @records = Synchronization.find(:all, :conditions => ['updated_at > ?', Time.parse(params[:updated_at])+1])
        end
        
        respond_with_records @records    
      end

      def create_record_auth
        if current_user.nil? then
          # FIXME: should never happen
          return render :json => "", :status => 401
        end

        create_record
      end

      def create_record
        
        Rails.logger.info "Params: " + params.to_s

        Rails.logger.info "Adding user_id to params, " + current_user.nil?.to_s + ", " + @model.new.respond_to?(:user_id).to_s
        if @model.new.respond_to?(:user_id) and not current_user.nil? then
          Rails.logger.info "Adding user_id to params" + current_user.id.to_s
          params[:user_id] = current_user.id
        end

        params.delete(:controller)
        params.delete(:model_name)
        params.delete(:action)
        params.delete(:locale)
        params.delete(:fb_access_token)
        params.delete(:fb_identifier)
        Rails.logger.info "Creating record with params: " + params.to_s
        
        record = @model.create_record(params)
        Rails.logger.info "Creating record finsihed"

        unless record.nil? then
          Rails.logger.info "Rendering object: " + record.as_json.to_s
          render :json => record
        else
          Rails.logger.info "Error"
          render :json => "ERROR", :status => 500
        end
      end

    protected

      def find_all_synchronizations
        @synchronizations = Synchronization.order('position ASC')
      end

      def find_page
        @page = ::Refinery::Page.where(:link_url => "/synchronizations").first
      end
      
      def check_model
        model_name = params[:model_name]
        Rails.logger.info "Checking model: #{params[:model_name]}, params: #{params}"

        @model = self.class.get_model(model_name)
        
        unless (@model.synchronizable?) then
          render :text => t('not_synchronizable')
        end
      end

      def self.get_model(p_model_name)
        Rails.logger.info "ASDF MODEL NAME: " + p_model_name.to_s
        model_name = p_model_name.singularize.camelize
        model_class = "::Refinery::" + model_name.pluralize + "::" + model_name
        
        Rails.logger.info "ASDF MODEL NAME: " + model_class.to_s
        Rails.logger.info "Syncable: " + model_class.constantize.synchronizable?.to_s
        Rails.logger.info "Authable: " + model_class.constantize.needs_authentication?.to_s
        return model_class.constantize
      end
      
      def respond_with_records(records)
        respond_to do |format|
          #format.html { render :text => t('format_error') }
          format.json { render :json => records }
          format.xml { render :xml => records }
        end
      end
  
      def forbidden(ex)
          Rails.logger.info "Forbidden: " + ex.why
          error_str = { :error => ex.why }
          render :json => error_str, :status => 403
      end

      def bad_request
          Rails.logger.info "Bad request exception got"
          error_str = { :error => "Bad request" }
          render :json => error_str, :status => 400
      end
      
      def record_conflict(ex)
          Rails.logger.info "Record is in conflict with: " + ex.record_in_conflict.as_json
          render :json => ex.record_in_conflict, :status => 409
      end
      
      def unauthorized(ex)
          Rails.logger.info "Unauthorized exception got"
          error_str = { :error => "Unauthorized" }
          render :json => error_str, :status => 401
      end

    end
  end
end
