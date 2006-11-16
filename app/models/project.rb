class Project < ActiveRecord::Base
  has_many :todos, :dependent => true
  has_many :notes, :dependent => true, :order => "created_at DESC"
  belongs_to :user
  
  # Project name must not be empty
  # and must be less than 255 bytes
  validates_presence_of :name, :message => "project must have a name"
  validates_length_of :name, :maximum => 255, :message => "project name must be less than 256 characters"
  validates_uniqueness_of :name, :message => "already exists", :scope =>"user_id"
  validates_format_of :name, :with => /^[^\/]*$/i, :message => "cannot contain the slash ('/') character"

  acts_as_list :scope => :user
  acts_as_state_machine :initial => :active, :column => 'state'
  extend NamePartFinder
  acts_as_todo_container :find_todos_include => :context
  
  state :active
  state :hidden, :enter => :hide_todos, :exit => :unhide_todos
  state :completed

  event :activate do
    transitions :to => :active,   :from => [:hidden, :complete]
  end
  
  event :hide do
    transitions :to => :hidden,   :from => [:active, :complete]
  end
  
  event :complete do
    transitions :to => :completed, :from => [:active, :hidden]
  end
  
  attr_protected :user

  def self.null_object
    NullProject.new
  end
  
  def description_present?
    attribute_present?("description")
  end
  
  def linkurl_present?
    attribute_present?("linkurl")
  end
  
  def hide_todos
    todos.each do |t|
      t.hide! unless t.completed?
      t.save
    end
  end
      
  def unhide_todos
    todos.each do |t|
      t.unhide! if t.project_hidden?
      t.save
    end
  end
  
  def transition_to(candidate_state)
    case candidate_state.to_sym
      when current_state
        return
      when :hidden
        hide!
      when :active
        activate!
      when :completed
        complete!
    end
  end
      
end

class NullProject
  
  def hidden?
    false
  end
  
  def nil?
    true
  end
  
end