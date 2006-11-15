class ConvertTodoToStateMachine < ActiveRecord::Migration

  class Todo < ActiveRecord::Base; belongs_to :project; end
  class Immediate < Todo; end
  class Deferred < Todo; end
  class Project < ActiveRecord::Base; end

  def self.up
    ActiveRecord::Base.transaction do
      add_column :todos, :state, :string, :limit => 20, :default => "immediate", :null => false
      @todos = Todo.find(:all)
      @todos.each do |todo|
        if todo.done?
          todo.state = 'completed'
        elsif todo.type == 'Deferred'
          todo.state = 'deferred'
        elsif !todo.project.nil? && todo.project.state == 'hidden'
          todo.state = 'project_hidden'
        else
          todo.state = 'active'
        end
        todo.save
      end
      rename_column :todos, :completed, :completed_at
      remove_column :todos, :done
      remove_column :todos, :type
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      add_column :todos, :done, :integer, :limit => 4, :default => 0, :null => false
      add_column :todos, :type, :string, :default => "Immediate", :null => false
      rename_column :todos, :completed_at, :completed
      @todos = Todo.find(:all)
      @todos.each do |todo|
        todo.done = todo.state == 'completed'
        todo.type = todo.type == 'deferred' ? 'Deferred' : 'Immediate'
        todo.save
      end
      remove_column :todos, :state
    end
  end
end
