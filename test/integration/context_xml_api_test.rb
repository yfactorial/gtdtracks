require File.dirname(__FILE__) + '/../test_helper'
require 'context_controller'
require 'context'
require 'action_controller/integration'

# Re-raise errors caught by the controller.
class ContextController; def rescue_action(e) raise e end; end

class ContextControllerXmlApiTest < ActionController::IntegrationTest
  fixtures :users, :contexts

  @@context_name = "@newcontext"
  @@valid_postdata = "<request><context><name>#{@@context_name}</name></context></request>"
  
  def setup
    assert_test_environment_ok
  end
  
  def test_fails_with_401_if_not_authorized_user
    authenticated_post_xml_to_context_create @@valid_postdata, 'nobody', 'nohow'
    assert_401_unauthorized
  end
  
 def test_fails_with_invalid_xml_format
   authenticated_post_xml_to_context_create "<foo></bar>"
   assert_404_invalid_xml
 end
    
  def test_fails_with_invalid_xml_format2
    authenticated_post_xml_to_context_create "<request><context></context></request>"
    assert_404_invalid_xml
  end
  
  def test_xml_simple_param_parsing
    authenticated_post_xml_to_context_create
    assert @controller.params.has_key?(:request)
    assert @controller.params[:request].has_key?(:context)
    assert @controller.params[:request][:context].has_key?(:name)
    assert_equal @@context_name, @controller.params[:request][:context][:name]
  end
  
  def test_fails_with_too_long_name
    invalid_with_long_name_postdata = "<request><context><name>foobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoo arfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoo arfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfoobarfo barfoobarfoobarfoobarfoobarfoobarfoobar</name></context></request>"
    authenticated_post_xml_to_context_create invalid_with_long_name_postdata
    assert_response_and_body 404, "Name context name must be less than 256 characters"
  end
  
  def test_fails_with_slash_in_name
    authenticated_post_xml_to_context_create "<request><context><name>foo/bar</name></context></request>"
    assert_response_and_body 404, "Name cannot contain the slash ('/') character"
  end
    
  def test_creates_new_project
    initial_count = Context.count
    authenticated_post_xml_to_context_create
    assert_response_and_body 200, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<context>\n  <name>#{@@context_name}</name>\n  <hide type=\"integer\">0</hide>\n  <id type=\"integer\">0</id>\n  <position type=\"integer\">1</position>\n</context>\n"
    assert_equal initial_count + 1, Context.count
    context1 = Context.find_by_name(@@context_name)
    assert_not_nil context1, "expected context '#{@@context_name}' to be created"
  end
  
  def test_fails_with_get_verb
    authenticated_get_xml "/context/create", users(:other_user).login, 'sesame', {}
  end
    
  private
    
  def authenticated_post_xml_to_context_create(postdata = @@valid_postdata, user = users(:other_user).login, password = 'sesame')
    authenticated_post_xml "/context/create", user, password, postdata
  end

  def assert_404_invalid_xml
    assert_response_and_body 404, "Expected post format is xml like so: <request><context><name>context name</name></context></request>."
  end
  
end