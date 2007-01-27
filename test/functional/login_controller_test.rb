require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'
require_dependency "login_system"

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < Test::Unit::TestCase
  fixtures :preferences, :users
  
  def setup
    assert_equal "test", ENV['RAILS_ENV']
    assert_equal "change-me", Tracks::Config.salt
    @controller = LoginController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @num_users_in_fixture = User.count
  end

  #============================================
  #Login and logout
  #============================================
    
  def test_invalid_login
    post :login, {:user_login => 'cracker', :user_password => 'secret', :user_noexpiry => 'on'}
    assert_response :success
    assert(!@response.has_session_object?(:user_id))
    assert_template "login"
  end
  
  def test_login_with_valid_admin_user
    @request.session['return-to'] = "/bogus/location"
    user = login('admin', 'abracadabra', 'on')
    assert_equal user.id, @response.session['user_id']
    assert_equal user.login, "admin"
    assert user.is_admin
    assert_equal "Login successful: session will not expire.", flash[:notice]
    assert_equal("http://#{@request.host}/bogus/location", @response.redirect_url)
  end
  
  def test_login_with_valid_standard_user
    user = login('jane','sesame', 'off')
    assert_equal user.id, @response.session['user_id']
    assert_equal user.login, "jane"
    assert user.is_admin == false || user.is_admin == 0
    assert_equal "Login successful: session will expire after 1 hour of inactivity.", flash[:notice]
    assert_redirected_to home_url
  end
  
  def test_login_with_no_users_redirects_to_signup
    User.delete_all
    get :login
    assert_redirected_to :controller => 'login', :action => 'signup'
  end
  
  def test_logout
    user = login('admin','abracadabra', 'on')
    get :logout
    assert_nil(session['user_id'])
    assert_redirected_to :controller => 'login', :action => 'login'
  end
  
  # Test login with a bad password for existing user
  # 
  def test_login_bad_password
    post :login, {:user_login => 'jane', :user_password => 'wrong', :user_noexpiry => 'on'}
    assert(!@response.has_session_object?(:user))
    assert_equal "Login unsuccessful", flash[:warning]
    assert_response :success
  end
  
  def test_login_bad_login
    post :login, {:user_login => 'blah', :user_password => 'sesame', :user_noexpiry => 'on'}
    assert(!@response.has_session_object?(:user))
    assert_equal "Login unsuccessful", flash[:warning]
    assert_response :success
  end
  
  private
  
  # Logs in a user and returns the user object found in the session object
  def login(login,password,expiry)
    post :login, {:user_login => login, :user_password => password, :user_noexpiry => expiry}
    assert_not_nil(session['user_id'])
    return User.find(session['user_id'])
  end
  
    
end
