require File.dirname(__FILE__) + '/../test_helper'
require 'date'

class TodoTest < Test::Rails::TestCase
  fixtures :todos, :users, :contexts, :preferences, :tags, :taggings

  def setup
    @not_completed1 = Todo.find(1).reload
    @not_completed2 = Todo.find(2).reload
    @completed = Todo.find(8).reload
  end
  
  # Test loading a todo item
  def test_load
    assert_kind_of Todo, @not_completed1
    assert_equal 1, @not_completed1.id
    assert_equal 1, @not_completed1.context_id
    assert_equal 2, @not_completed1.project_id
    assert_equal "Call Bill Gates to find out how much he makes per day", @not_completed1.description
    assert_nil @not_completed1.notes
    assert @not_completed1.completed? == false
    assert_equal 1.week.ago.utc.beginning_of_day.strftime("%Y-%m-%d %H:%M"), @not_completed1.created_at.strftime("%Y-%m-%d %H:%M")
    assert_equal 2.week.from_now.utc.beginning_of_day.strftime("%Y-%m-%d"), @not_completed1.due.strftime("%Y-%m-%d")
    assert_nil @not_completed1.completed_at
    assert_equal 1, @not_completed1.user_id
  end
  
  def test_completed
    assert_kind_of Todo, @completed
    assert @completed.completed?
    assert_not_nil @completed.completed_at
  end
  
  def test_completed_at_cleared_after_toggle_to_active
    assert_kind_of Todo, @completed
    assert @completed.completed?
    @completed.toggle_completion!
    assert @completed.active?
    assert_nil @completed.completed_at
  end
  
  
  # Validation tests
  #
  def test_validate_presence_of_description
    assert_equal "Call dinosaur exterminator", @not_completed2.description
    @not_completed2.description = ""
    assert !@not_completed2.save
    assert_equal 1, @not_completed2.errors.count
    assert_equal "can't be blank", @not_completed2.errors.on(:description)
  end
  
  def test_validate_length_of_description
    assert_equal "Call dinosaur exterminator", @not_completed2.description
    @not_completed2.description = generate_random_string(101)
    assert !@not_completed2.save
    assert_equal 1, @not_completed2.errors.count
    assert_equal "is too long (maximum is 100 characters)", @not_completed2.errors.on(:description)
  end
  
  def test_validate_length_of_notes
    assert_equal "Ask him if I need to hire a skip for the corpses.", @not_completed2.notes
    @not_completed2.notes = generate_random_string(60001)
    assert !@not_completed2.save
    assert_equal 1, @not_completed2.errors.count
    assert_equal "is too long (maximum is 60000 characters)", @not_completed2.errors.on(:notes)
  end

  def test_validate_show_from_must_be_a_date_in_the_future
    t = @not_completed2
    t[:show_from] = 1.week.ago.to_date # we have to set this via the indexer because show_from=() updates the state
                                       # and actual show_from value appropriately based on the date
    assert_equal 1.week.ago.to_date, t.show_from
    assert !t.save
    assert_equal 1, t.errors.count
    assert_equal "must be a date in the future", t.errors.on(:show_from)
  end
  
  def test_defer_an_existing_todo
    @not_completed2
    assert_equal :active, @not_completed2.current_state
    @not_completed2.show_from = next_week
    assert @not_completed2.save, "should have saved successfully" + @not_completed2.errors.to_xml
    assert_equal :deferred, @not_completed2.current_state
  end
  
  def test_create_a_new_deferred_todo
    user = users(:other_user)
    todo = user.todos.build
    todo.show_from = next_week
    todo.context_id = 1
    todo.description = 'foo'
    assert todo.save, "should have saved successfully" + todo.errors.to_xml
    assert_equal :deferred, todo.current_state
  end

  def test_create_a_new_deferred_todo_by_passing_attributes
    user = users(:other_user)
    todo = user.todos.build(:show_from => next_week, :context_id => 1, :description => 'foo')
    assert todo.save, "should have saved successfully" + todo.errors.to_xml
    assert_equal :deferred, todo.current_state
  end

  def test_feed_options
    opts = Todo.feed_options(users(:admin_user))
    assert_equal 'Tracks Actions', opts[:title], 'Unexpected value for :title key of feed_options'
    assert_equal 'Actions for Admin Schmadmin', opts[:description], 'Unexpected value for :description key of feed_options'
  end

  def test_toggle_completion
    t = @not_completed1
    assert_equal :active, t.current_state
    t.toggle_completion!
    assert_equal :completed, t.current_state
    t.toggle_completion!
    assert_equal :active, t.current_state
  end

  def test_activate_also_saves
    t = @not_completed1
    t.show_from = 1.week.from_now.to_date
    t.save!
    assert t.deferred?
    t.reload
    t.activate!
    assert t.active?
    t.reload
    assert t.active?
  end

  def test_project_returns_null_object_when_nil
    t = @not_completed1
    assert !t.project.is_a?(NullProject)
    t.project = nil
    assert t.project.is_a?(NullProject)
  end

  def test_initial_state_defaults_to_active
    t = Todo.new
    t.description = 'foo'
    t.context_id = 1
    t.save!
    t.reload
    assert_equal :active, t.current_state
  end

  def test_initial_state_is_deferred_when_show_from_in_future
    t = Todo.new
    t.user = users(:admin_user)
    t.description = 'foo'
    t.context_id = 1
    t.show_from = 1.week.from_now.to_date
    t.save!
    t.reload
    assert_equal :deferred, t.current_state
  end
  
  def test_todo_is_not_starred
    assert !@not_completed1.starred?
  end
  
  def test_todo_2_is_not_starred
    assert !Todo.find(2).starred?
  end
  
  def test_todo_is_starred_after_starred_tag_is_added
    @not_completed1.add_tag('starred')
    assert @not_completed1.starred?
  end

  def test_todo_is_starred_after_toggle_starred
    @not_completed1.toggle_star!
    assert @not_completed1.starred?
  end
  
  def test_todo_is_not_starred_after_toggle_starred_twice
    @not_completed1.toggle_star!
    @not_completed1.toggle_star!
    assert !@not_completed1.starred?
  end
  
end
