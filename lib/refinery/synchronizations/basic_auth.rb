Warden::Strategies.add(:basic) do
  def auth
    @auth ||= Rack::Auth::Basic::Request.new(env)
  end
        
  def valid?
    Rails.logger.info "Valid basic auth request? #{auth.provided? && auth.basic? && auth.credentials}"
    return auth.provided? && auth.basic? && auth.credentials
  end

  def authenticate!
    if not self.valid? then
      Rails.logger.info "Credentials not valid"
      raise Unauthorized
    end
    
    email = auth.credentials.first
    password = auth.credentials.last

    Rails.logger.info "Authenticate user with email: #{email} and password: #{password}, anon_user: #{params[:anonymous_user]}"
    user = ::Refinery::User.find_by_email(email)
    if user.nil?
      user = ::Refinery::User.find_by_username(email)
    end
    unless user.nil?
      if (email == user.username || email == user.email) && user.valid_password?(password) then
        if not params[:anonymous_user].nil? then
          Rails.logger.info "Anonymous user is defined: #{params[:anonymous_user]}"
          anonymous_user = ::Refinery::User.find_by_email(params[:anonymous_user])
        end
        if not anonymous_user.nil? and anonymous_user.anonymous then
          user.merge_collected_activities(anonymous_user)
          Rails.logger.info "Deleting anonim user"
          anonymous_user.destroy()
          Rails.logger.info "Anonim user deleted"
        end
        Rails.logger.info "User authentication succeeded!"
        success!(user)

        return user
      else
        Rails.logger.info "User authentication failed!"
        raise Unauthorized
      end
    end

    Rails.logger.info "User authentication failed!"
    raise Unauthorized
  end
end
