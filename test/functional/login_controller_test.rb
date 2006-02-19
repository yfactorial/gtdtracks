require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'
require_dependency "login_system"

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    assert_equal "test", ENV['RAILS_ENV']
    @controller = LoginController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_login_with_invalid_user
    post :login, {:user_login => 'cracker', :user_password => 'secret'}
    assert_response :success
    assert_template 'login/login'
    assert_nil(session['user'])
  end

  def test_login_with_valid_admin_user
    user = login('admin','abracadabra')
    assert_equal "Login successful: session will expire after 1 hour of inactivity.", flash['notice']
    assert_redirected_to :controller => 'todo', :action => 'list'
    assert_equal 'admin', user.login
    assert_equal 1, user.is_admin
  end

  def test_login_with_valid_standard_user
    user = login('jane','sesame')
    assert_equal "Login successful: session will expire after 1 hour of inactivity.", flash['notice']
    assert_redirected_to :controller => 'todo', :action => 'list'
    assert_equal 'jane', user.login
    assert_equal 0, user.is_admin
  end

  def test_logout
    user = login('admin','abracadabra')
    get :logout
    assert_nil(session['user'])
    assert_redirected_to :controller => 'login', :action => 'login'
  end

  # TODO: Not sure how to test whether the user is blocked if the admin user is
  # not logged in. I tried setting the session[:user] cookie to nil first,
  # but that generated an error.
  #
  def test_create
    post :signup, :user => {:login => 'newbie', 
                            :password => 'newbiepass',
                            :password_confirmation => 'newbiepass'}
    assert_equal "Signup successful", flash['notice']
    assert_redirected_to :controller => 'todo', :action => 'list'
    assert_not_nil(session['user'])
    user = User.find(session['user'].id)
    assert_equal 'newbie', user.login
    assert_equal 0, user.is_admin
  end

end
