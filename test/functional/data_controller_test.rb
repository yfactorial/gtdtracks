require File.dirname(__FILE__) + '/../test_helper'
require 'data_controller'

# Re-raise errors caught by the controller.
class DataController; def rescue_action(e) raise e end; end

class DataControllerTest < Test::Rails::TestCase
  fixtures :users, :preferences, :projects, :notes

  def setup
    @controller = DataController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_csv_export_completes_without_error
    login_as :admin_user
    get :csv_notes
  end
end
