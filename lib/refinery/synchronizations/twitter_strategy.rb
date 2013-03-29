# -*- encoding : utf-8 -*-
require 'twitter'

class UserMailer < ActionMailer::Base
  default :from => "no-reply@toplamax.com"

  def welcome_email(user)
    @user = user
    mail(:to => user.email, :subject => "Welcome to My Awesome Site", :body => "Hello guys")
  end
end

Warden::Strategies.add(:twitter) do
  def valid?
    Rails.logger.info "Twitter auth is valid? token: #{params[:twitter_auth_token]}, secret: #{params[:twitter_auth_secret]} // #{defined? params[:twitter_auth_token] and not params[:twitter_auth_token].nil?}"
    return ((defined? params[:twitter_auth_token] and not params[:twitter_auth_token].nil?) and (defined? params[:twitter_auth_secret] and not params[:twitter_auth_secret].nil?))
  end

  def authenticate!
    Rails.logger.info "Twitter Auth called"
    begin
      Rails.logger.info "Authenticating with twitter credentials, auth token: #{params[:twitter_auth_token]}, secret: #{params[:twitter_auth_secret]}"
      Twitter.configure do |config|
        config.consumer_key       = '9niuE12gC5iJb9ClwgQ'
        config.consumer_secret    = '7YTN6OoWZSDpkAeNISORdJN1sTfFelk3NbqxqbbtI'
        config.oauth_token        = params[:twitter_auth_token]
        config.oauth_token_secret = params[:twitter_auth_secret]
      end

      twitter_graph_user = Twitter.user

      # Facebook object is saved here
      Rails.logger.info "Twitter user is: #{twitter_graph_user.inspect}"
      twitter_user = ::Refinery::Twitters::Twitter.identify(twitter_graph_user, params[:twitter_auth_token], params[:twitter_auth_secret]) 

      if twitter_user.user.nil? then
        Rails.logger.info "TwitterUser is nil, new user needs to be registered"
        begin
          user = Warden::Strategies[:basic].new(request.env).authenticate!
        rescue Unauthorized
        end

        if user.nil? then
          Rails.logger.info "User with basic auth is nil"
          random_password = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{twitter_user.identifier}--#{params[:twitter_auth_token]}--")[0,10]
          user = ::Refinery::User.new
          user.anonymous = true
          user.password = random_password
          user.password_confirmation = random_password
          user.manual_signup = false
        end

        if user.anonymous then
          Rails.logger.info "User is anonymous, setting stuff"
          user.first_name = twitter_graph_user.attrs[:name].split(" ").first
          if not twitter_graph_user.attrs[:name].split(" ").second.nil? then
            user.last_name = twitter_graph_user.attrs[:name].split(" ").second
          else
            user.last_name = " "
          end

          Rails.logger.info "ASDFASDFADSF: #{twitter_user.identifier}"
          user.email = "#{twitter_user.identifier}@toplamaxTwitter.com"
          user.username = "#{twitter_user.identifier}@toplamaxTwitter.com"
          user.manual_signup = false

          user.timeline_share = "false"
          user.verification_code = rand(899999)+100000
          user.verified = false

          user.anonymous = false
          
          Rails.logger.info "Anonym was, sending email"
          #UserMailer.welcome_email(user).deliver
          
          user.save
        else
          user.timeline_share = "true"
          Rails.logger.info "User is found with basic auth: #{user.first_name}"
        end
        
        twitter_user.user = user
        twitter_user.user_id = user.id
        twitter_user.save
      else
        if Warden::Strategies[:basic].new(request.env).valid? then
          begin
            anonim_user = Warden::Strategies[:basic].new(request.env).authenticate!
          rescue Unauthorized
          end
        end

        user = twitter_user.user

        Rails.logger.info "TWUser is valid: #{user.first_name} #{user.last_name} #{user.email} #{user.id}"

        if not anonim_user.nil? and user.id != anonim_user.id then

          if anonim_user.anonymous then            
            Rails.logger.info "The user is a anonymous, merging collected activities"
            user.merge_collected_activities(anonim_user)
            anonim_user.destroy()
            Rails.logger.info "Anonim user is destroyed"
          else
            Rails.logger.info "The user is a real user, merging accounts"
            twitter_user.user = anonim_user
            twitter_user.user_id = anonim_user.id
            twitter_user.save
            anonim_user.merge_collected_activities(user)

            user.destroy
            user = anonim_user
            Rails.logger.info "Facebook user account is destroyed (and merged to a basic account)"
          end
          
        end
      end
      
      if not user.nil? then
        Rails.logger.info "User is already registered: #{user.email} #{user.verification_code.to_s}"
      end
      success!(user)

      return user
    rescue Exception => e
      raise Unauthorized unless twitter_user
    end
  end

end
