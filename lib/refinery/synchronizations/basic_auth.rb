Warden::Strategies.add(:basic) do
  def auth
    @auth ||= Rack::Auth::Basic::Request.new(env)
  end
        
  def valid?
    Rails.logger.info "Valid basic auth request? #{auth.provided? && auth.basic? && auth.credentials}"
    return auth.provided? && auth.basic? && auth.credentials
  end

  def authenticate!
    email = auth.credentials.first
    password = auth.credentials.last

    Rails.logger.info "Authenticate user with email: #{email} and password: #{password}"
    user = ::Refinery::User.find_by_email(email)
    if user.nil?
      user = ::Refinery::User.find_by_username(email)
    end
    unless user.nil?
      if (email == user.username || email == user.email) && user.valid_password?(password) then
        Rails.logger.info "User authentication succeeded!: #{user.email}"
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
