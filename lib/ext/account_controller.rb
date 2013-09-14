class AccountController < ApplicationController
  def try_ssl_auth
    # First check REMOTE_USER variable
    tmpRemoteUser  = request.env["REMOTE_USER"]
    if tmpRemoteUser:
      # Interpret REMOTE_USER as user login name (e.g., using BasicAuth)
      user = User.find_by_login( tmpRemoteUser )
      unless user.nil?
        # Valid user
        logger.info ">>> Login REMOTE_USER: " + user
        return false if !user.active?
        user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
        self.logged_user = user
        return true
      end

      # Interpret REMOTE_USER as a DN. Extract the email
      matchRes = tmpRemoteUser.scan(/emailAddress=([\w\d\-\.]+@[\w\d\-\.]+\.[\w\d]+)\//).flatten
      tmpEmail = matchRes.first
      if tmpEmail.nil?
        # Try again assuming emailAddress is the last item
        matchRes = tmpRemoteUser.scan(/emailAddress=([\w\d\-\.]+@[\w\d\-\.]+\.[\w\d]+)/).flatten
        tmpEmail = matchRes.first
      end

      # Save the email in the session if available.
      if tmpEmail
        logger.info ">>> Found email in REMOTE_USER: " + tmpEmail
        session[:email] = tmpEmail
      else
        logger.info ">>> No email in REMOTE_USER found. REMOTE_USER="+tmpRemoteUser
      end
    end

    # Try the variable SSL_CLIENT_S_DN_Email next
    if session[:email].nil? and request.env['SSL_CLIENT_S_DN_Email']
      session[:email] = request.env["SSL_CLIENT_S_DN_Email"]
    end

    # Try the variable SSL_CLIENT_S_DN_CN next
    if session[:email].nil? and request.env['SSL_CLIENT_S_DN_CN']
      session[:email] = request.env["SSL_CLIENT_S_DN_CN"]
    end

    # Try the variable HTTP_SSL_CLIENT_S_DN next
    if session[:email].nil? and request.env['HTTP_SSL_CLIENT_S_DN']
      tmp = request.env['HTTP_SSL_CLIENT_S_DN'].scan(/emailAddress=([\w\d\-\.]+@[\w\d\-\.]+\.[\w\d]+)\//).flatten
      session[:email] = tmp.first
    end

    if session[:email]
      logger.info ">>> Login with certificate email: " + session[:email]
      user = User.find_by_mail(session[:email])
      # TODO: try to register on the fly
      unless user.nil?
        # Valid user
        return false if !user.active?
        user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
        self.logged_user = user
        return true
      end
    end
    return false
  end

  def ssl_login
    if params[:force_ssl]
      if try_ssl_auth
        redirect_back_or_default :controller => 'my', :action => 'page'
        return
      else
        render_403
        return
      end
    end
    if !User.current.logged? and not params[:skip_ssl]
      if try_ssl_auth
        redirect_back_or_default :controller => 'my', :action => 'page'
        return
      end
    end

    login
  end
end
