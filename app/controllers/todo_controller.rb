class TodoController < ApplicationController
  
  helper :todo
  model :context, :project
  
	before_filter :login_required
	# caches_action :list, :completed
  layout "standard"
    
	# Main method for listing tasks
	# Set page title, and fill variables with contexts and done and not-done tasks
	#
	def list
		@page_title = "List tasks"
		@projects = Project.find_all
		@places = Context.find_all
	  @shown_places = Context.find_all( "hide=0", "id ASC")
    @hidden_places = Context.find_all( "hide=1")
		@done = Todo.find_all( "done=1", "completed DESC", 5 )
		@count = Todo.count( "done=0" )
	end


	# List the completed tasks, sorted by completion date
	#
	# Use days declaration? 1.day.ago?
  def completed
    @page_title = "Completed tasks"
    today_query = "DATE_SUB(CURDATE(),INTERVAL 1 DAY) <= completed"
    week_query = "DATE_SUB(CURDATE(),INTERVAL 2 DAY) >= completed 
                  AND DATE_SUB(CURDATE(),INTERVAL 7 DAY) <= completed"
    month_query = "DATE_SUB(CURDATE(),INTERVAL 8 DAY) >= completed 
                  AND DATE_SUB(CURDATE(),INTERVAL 31 DAY) <= completed"
    @done_today = Todo.find_by_sql( "SELECT * FROM todos WHERE done = 1 AND #{today_query} 
                  ORDER BY completed DESC;" )
    @done_this_week = Todo.find_by_sql( "SELECT * FROM todos WHERE done = 1 AND #{week_query} 
                  ORDER BY completed DESC;" )
    @done_this_month = Todo.find_by_sql( "SELECT * FROM todos WHERE done = 1 AND #{month_query}     
                  ORDER BY completed DESC;" )
  end
  
  # Archived completed items, older than 31 days
	#
  def completed_archive
    @page_title = "Archived completed tasks"
    archive_query = "DATE_SUB(CURDATE(),INTERVAL 32 DAY) >= completed"
    @done_archive = Todo.find_by_sql( "SELECT * FROM todos WHERE done = 1 AND #{archive_query} 
                  ORDER BY completed DESC;" )
  end
	
	# Called by a form button
	# Parameters from form fields should be passed to create new item
	#
	def add_item
    @item = Todo.new
		@item.attributes = @params["item"]
		
	  if @item.save
		  flash["confirmation"] = "Next action was successfully added"
			redirect_to( :action => "list" )
		else
		  flash["warning"] = "Couldn't add the action because of an error"
		  redirect_to( :action => "list" )
		end
	end
	
	
	def edit
    @item = Todo.find(@params['id'])
    @belongs = @item.project_id
		@projects = Project.find_all
		@places = Context.find_all
    @page_title = "Edit task: #{@item.description}"
  end


  def update
    @item = Todo.find(@params['item']['id'])
    @item.attributes = @params['item']
    if @item.save
      flash["confirmation"] = 'Next action was successfully updated'
      redirect_to :action => 'list'
    else
      flash["warning"] = 'Next action could not be updated'
      redirect_to :action => 'list'
    end
  end
	

	def destroy
	  item = Todo.find(@params['id'])
		if item.destroy
			flash["confirmation"] = "Next action was successfully deleted"
			redirect_to :action => "list"
		else
			flash["warning"] = "Couldn't delete next action"
			redirect_to :action => "list"
		end
	end
	
	# Toggles the 'done' status of the action
	#
	def toggle_check
	  item = Todo.find(@params['id'])
		
		item.toggle!('done')
		
		if item.save
		  flash["confirmation"] = "Next action marked as completed"
			redirect_to( :action => "list" )
		else
		  flash["warning"] = "Couldn't mark action as completed"
			redirect_to( :action => "list" )
		end	
	end
	
	
end
