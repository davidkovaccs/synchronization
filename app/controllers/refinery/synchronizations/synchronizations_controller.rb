require 'devise'
#require 'backports'
require "backports/1.8.7"

module Refinery
  module Synchronizations
    class SynchronizationsController < ::ApplicationController
     
      before_filter :check_model, :only => [:sync_model, :sync_model_auth, :create_record, :model_indexes, :model_indexes_auth]
      # before_filter :authenticate_refinery_user!, :only => [:sync_model_auth, :synchronizations_all, :create_record, :login, :update_user, :verify_user, :model_indexes_auth]
      # FIXME: authenticate_refinery_user! should do this
      before_filter :fb_test, :only => [:sync_model_auth, :synchronizations_all, :create_record, :login, :update_user, :verify_user, :model_indexes_auth]
    
      rescue_from ::BadRequest, :with => :bad_request
      rescue_from ::RecordConflict, :with => :record_conflict
      rescue_from ::Forbidden, :with => :forbidden
      rescue_from ::Unauthorized, :with => :unauthorized

      def fb_test
        Rails.logger.info "Testing fb: #{params[:fb_auth_token]}"
        if Warden::Strategies[:facebook].new(request.env).valid? then
          Rails.logger.info "Testing22 fb: #{params[:fb_auth_token]}"
          Warden::Strategies[:facebook].new(request.env).authenticate!
          env['warden'].authenticate(:facebook)
          return
        end
        if not current_refinery_user.nil?
          Rails.logger.info "Testing basic0: #{current_refinery_user.first_name}"
        end
        Rails.logger.info "Testing basic end"
        env['warden'].authenticate(:facebook, :basic)
      end

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

      def login
        Rails.logger.info "Login"
        unless current_refinery_user.nil? then
          Rails.logger.info "SyncLogin - Refinery user is ok: #{current_refinery_user.first_name}"
          render :json => current_refinery_user, :status => 200
        else
          Rails.logger.info "SyncLogin: Refinery user is failed"
          raise Unauthorized
        end
      end

      def register
        user = env['warden'].authenticate(:basic)
        if user.nil? then
          Rails.logger.info "User with basic auth is nil"
          raise Unauthorized
        end

        user.username = params[:email]
        user.email = params[:email]
        user.password = params[:password]
        user.password_confirmation = params[:password]
        user.phone = params[:phone]
        user.first_name = params[:first_name]
        user.last_name = params[:last_name]
        user.timeline_share = "true"
        user.verified = false
        user.verification_code = rand(899999)+100000
        user.anonymous = false

        if user.save then
          render :json => user
        else
          error_str = user.errors.full_messages.to_s
          Rails.logger.info "User not saved properly: #{error_str}"
          render :json => { :error => error_str }, :status => 409
        end
        #user = User.new(:username => params[:email], :email => params[:email], :password => params[:password], :password_confirmation => params[:password], :phone => params[:phone],
        #    :first_name => params[:first_name], :last_name => params[:last_name], :timeline_share => "true", :verified => false, :verification_code => rand(899999)+100000, :anonymous => false)
      end

      def register_anonymously
        user = User.new(:username => params[:email], :email => params[:email], :password => params[:password], :password_confirmation => params[:password],
            :first_name => params[:first_name], :last_name => params[:last_name], :timeline_share => "true", :verified => false, :anonymous => true)
        if user.save then
          render :json => user
        else
          error_str = user.errors.full_messages.to_s
          Rails.logger.info "User not saved properly: #{error_str}"
          render :json => { :error => error_str }, :status => 409
        end
      end

      def verify_user
        unless current_refinery_user.nil? then
            if params[:verification_code].nil? then
              raise BadRequest
            elsif current_refinery_user.verification_code == params[:verification_code].to_i then
              current_refinery_user.verified = true
              current_refinery_user.save
              render :json => current_refinery_user, :status => 200
            else
              raise BadRequest
            end
        else
          raise Unauthorized
        end
      end
      
      def update_user
        if current_refinery_user.nil? then
          raise Unauthorized
        end

        # UPDATE PHONE
        unless params[:phone].nil? then
          if params[:phone].length != 10 then
            Rails.logger.info "Phone length is  not 10: #{params[:phone]}"
            raise BadRequest
          end
          current_refinery_user.phone = params[:phone]
          current_refinery_user.verified = false
          current_refinery_user.verification_code = rand(899999)+100000
        end

        # UPDATE NAME
        unless params[:name].nil? then
          first_name = params[:name].split(" ").first
          last_name = params[:name].split(" ").second
          if first_name.nil? or last_name.nil? then
            Rails.logger.info "No first_name: #{first_name} or last name: #{last_name} where name: #{params[:name]}"
            raise BadRequest
          end
          current_refinery_user.first_name = first_name
          current_refinery_user.last_name = last_name
        end

        # UPDATE EMAIL
        #unless params[:email].nil? then
        #  if not params[:email] =~ /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/ then
        #    Rails.logger.info "Please specify a correct email address"
        #    raise BadRequest
        #  end
        #  user_with_this_email = ::Refinery::User.find_by_email(params[:email])
        #  if not user_with_this_email.nil? and user_with_this_email != current_refinery_user then
        #    Rails.logger.info "There is another user with this email address"
        #    raise BadRequest
        #  end
        #  current_refinery_user.email = params[:email]
        #end

        # UPDATE BIRTHDAY
        unless params[:birthday].nil? then
          current_refinery_user.birthday = params[:birthday]
        end
        
        # UPDATE TIMELINE SHARE
        unless params[:timeline_share].nil? then
          current_refinery_user.timeline_share = params[:timeline_share]
        end

        # UPDATE GENDER
        unless params[:gender].nil? then
          Rails.logger.info "Gender is: '#{params[:gender]}'"
          if params[:gender].eql?("male") then
            current_refinery_user.gender = "male"
          else
            current_refinery_user.gender = "female"
          end
        end

        # TRY TO SAVE THE USER
        if current_refinery_user.save then
          if params[:phone].present? then
            sm = ::Refinery::Sms::Sm.create(:message => "Your verification code is: #{current_refinery_user.verification_code}", :to_number => params[:phone], :user_id => current_refinery_user.id)
            Rails.logger.info "Sm created: " + sm.to_s
            resp = sm.send_to_dst
            Rails.logger.info "Sm sent: " + resp.body + ", #{sm.transaction_id}"
          end
          render :json => current_refinery_user, :status => 200
        else
          Rails.logger.info "Can't save user: #{current_refinery_user.errors.full_messages}"
          raise BadRequest
        end
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
          if current_refinery_user.nil? then
            # FIXME: should never happen
            return render :json => "", :status => 401
          end
  
          if params[:updated_at].nil? then
            @records = @model.find(:all, :conditions => ['user_id = ?', current_refinery_user.id], :select => "id").collect(&:id)
          end
          
          return respond_with_records @records
      end
  
      # ------------------------------
      # custom synchronization methods
      # FIXME: +1
      def sync_model_auth
          if current_refinery_user.nil? then
            # FIXME: should never happen
            return render :json => "", :status => 401
          end
  
          if params[:updated_at].nil? then
            @records = @model.find(:all, :conditions => ['user_id = ?', current_refinery_user.id])
          else
            @records = @model.find(:all, :conditions => ['updated_at > ? and user_id = ?', Time.parse(params[:updated_at])+1, current_refinery_user.id])
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

        # FIXME: HACK
        ::Refinery::CollectedActivityitems::CollectedActivityitem.first
        ::Refinery::RedeemedItems::RedeemedItem.first
        ::Refinery::Referrals::Referral.first
        ::Refinery::Signups::Signup.first
        ::Refinery::TeamMembers::TeamMember.first
        ::Refinery::ClubMembers::ClubMember.first
        
        for obj_class in $objects_needs_auth do
          Rails.logger.info "Obj that needs auth: #{obj_class.name}"
          obj = nil
          if params[:updated_at].nil? then
            obj = obj_class.find(:first, :order => "updated_at DESC", :conditions => ['user_id = ?', current_refinery_user.id])
          else
            obj = obj_class.find(:first, :order => "updated_at DESC", :conditions => ['updated_at > ? and user_id = ?', Time.parse(params[:updated_at])+1, current_refinery_user.id])
          end
          
          unless obj.nil? then
            new_rec = Synchronization.new(:method_name => "update", :model_name => obj_class.name.split('::').last, :model_updated_at => obj.updated_at, :updated_at => obj.updated_at)
            new_rec.id = generate_model_id(obj_class.name, current_refinery_user.id, true)
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
        unless current_refinery_user.nil?
          Rails.logger.info "User is authenticated! User id: #{current_refinery_user.id}"
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

      def create_record
        if current_refinery_user.nil? then
          # FIXME: should never happen
          return render :json => "", :status => 401
        end
        
        Rails.logger.info "Params: " + params.to_s

        Rails.logger.info "Adding user_id to params, " + current_refinery_user.nil?.to_s + ", " + @model.new.respond_to?(:user_id).to_s
        if @model.new.respond_to?(:user_id) and not current_refinery_user.nil? then
          Rails.logger.info "Adding user_id to params" + current_refinery_user.id.to_s
          params[:user_id] = current_refinery_user.id
        end

        params.delete(:controller)
        params.delete(:model_name)
        params.delete(:action)
        params.delete(:locale)
        params.delete(:fb_auth_token)
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
