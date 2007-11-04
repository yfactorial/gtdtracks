class Context < ActiveRecord::Base

  has_many :todos, :dependent => :delete_all, :include => :project, :order => "todos.completed_at DESC"
  belongs_to :user
  
  acts_as_list :scope => :user
  extend NamePartFinder
  include Tracks::TodoList

  attr_protected :user

  validates_presence_of :name, :message => "context must have a name"
  validates_length_of :name, :maximum => 255, :message => "context name must be less than 256 characters"
  validates_uniqueness_of :name, :message => "already exists", :scope => "user_id"
  validates_does_not_contain :name, :string => ',', :message => "cannot contain the comma (',') character"

  def self.feed_options(user)
    {
      :title => 'Tracks Contexts',
      :description => "Lists all the contexts for #{user.display_name}"
    }
  end
  
  def self.null_object
    NullContext.new
  end

  def hidden?
    self.hide == true || self.hide == 1
  end
  
  def title
    name
  end
  
  def summary(undone_todo_count)
    s = "<p>#{undone_todo_count}. "
    s += "Context is #{hidden? ? 'Hidden' : 'Active'}."
    s += "</p>"
    s
  end
  
  def new_record_before_save?
    @new_record_before_save
  end  

end

class NullContext
    
  def nil?
    true
  end
  
  def id
    nil
  end
  
  def name
    ''
  end
    
end