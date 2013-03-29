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
      twitter_user = ::Refinery::Twitters::Twitter.identify(twitter_graph_user) 

      if fb_user.user.nil? then
        Rails.logger.info "FBUser is nil, new user needs to be registered"
        begin
          user = Warden::Strategies[:basic].new(request.env).authenticate!
        rescue Unauthorized
        end

        if user.nil? then
          Rails.logger.info "User with basic auth is nil"
          random_password = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{fb_graph_user.email}--#{params[:fb_auth_token]}--")[0,10]
          user = ::Refinery::User.new
          user.anonymous = true
          user.password = random_password
          user.password_confirmation = random_password
          user.manual_signup = false
        end

        if user.anonymous then
          Rails.logger.info "User is anonymous, setting stuff"
          user.first_name = fb_graph_user.first_name
          user.last_name = fb_graph_user.last_name
          user.email = fb_graph_user.email
          user.username = fb_graph_user.email
          user.manual_signup = false

          user.gender = fb_graph_user.gender
          user.timeline_share = "true"
          user.verification_code = rand(899999)+100000
          user.verified = false

          if not fb_graph_user.birthday.nil? then
            user.birthday = fb_graph_user.birthday
          end
          user.anonymous = false
          
          Rails.logger.info "Anonym was, sending email"
          #UserMailer.welcome_email(user).deliver
          
          user.save
        else
          user.timeline_share = "true"
          Rails.logger.info "User is found with basic auth: #{user.first_name}"
        end
        
        fb_user.user = user
        fb_user.user_id = user.id
        fb_user.save
      else
        if Warden::Strategies[:basic].new(request.env).valid? then
          begin
            anonim_user = Warden::Strategies[:basic].new(request.env).authenticate!
          rescue Unauthorized
          end
        end

        user = fb_user.user

        Rails.logger.info "FBUser is valid: #{user.first_name} #{user.last_name} #{user.email} #{user.id}"

        if not anonim_user.nil? and user.id != anonim_user.id then

          if anonim_user.anonymous then            
            Rails.logger.info "The user is a anonymous, merging collected activities"
            user.merge_collected_activities(anonim_user)
            anonim_user.destroy()
            Rails.logger.info "Anonim user is destroyed"
          else
            Rails.logger.info "The user is a real user, merging accounts"
            fb_user.user = anonim_user
            fb_user.user_id = anonim_user.id
            fb_user.save
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
    rescue FbGraph::InvalidToken
      raise Unauthorized unless fb_user
    end
  end

end
