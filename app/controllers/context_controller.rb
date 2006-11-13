class ContextController < ApplicationController

  helper :todo

  prepend_before_filter :login_required
  layout "standard"

  def index
    list
    render_action "list"
  end

  # Main method for listing contexts
  # Set page title, and collect existing contexts in @contexts
  #
  def list
    self.init
    @page_title = "TRACKS::List Contexts"
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @contexts.to_xml( :except => :user_id ) }
    end
  end

  # Filter the projects to show just the one passed in the URL
  # e.g. <home>/context/<context_name> shows just <context_name>.
  #
  def show
    init
    check_user_set_context
    init_todos
    @page_title = "TRACKS::Context: #{@context.name}"
  end
  
  # Example XML usage: curl -H 'Accept: application/xml' -H 'Content-Type: application/xml'
  #                    -u username:password
  #                    -d '<request><context><name>new context_name</name></context></request>'
  #                    http://our.tracks.host/context/create
  #
  def create
    @context = @user.contexts.build
    params_are_invalid = true
    if (params['context'] || (params['request'] && params['request']['context']))
      @context.attributes = params['context'] || params['request']['context']
      params_are_invalid = false
    end
    @context.name = deurlize(@context.name)
    @saved = @context.save
    @context_not_done_counts = { @context.id => 0 }
    respond_to do |wants|
      wants.js
      wants.xml do
        if @context.new_record? && params_are_invalid
          render_failure "Expected post format is xml like so: <request><context><name>context name</name></context></request>."
        elsif @context.new_record?
          render_failure @context.errors.full_messages.join(', ')
        else
          render :xml => @context.to_xml( :except => :user_id )
        end
       end
    end
  end
  
  # Called by a form button
  # Parameters from form fields are passed to create new action
  # in the selected context.
  def add_item
    self.init
    @item = @user.todos.build
    @item.attributes = params["todo"]

    if @item.due?
      @date = parse_date_per_user_prefs(params["todo"]["due"])
      @item.due = @date.to_s(:db)
    else
      @item.due = ""
    end

    @saved = @item.save
    if @saved
      # This reports real count +1 for some reason that I don't understand
      # Almost identical code for add_item in projects reports correct num
      @up_count = Todo.find(:all, :conditions => ["todos.user_id = ? and todos.done = ? and todos.context_id IN (?)", @user.id, false, @item.context_id]).size.to_s
    end
     
    return if request.xhr?
    
    # fallback for standard requests
    if @saved
      flash[:notice] = 'Added new next action.'
      redirect_to :controller => 'todo', :action => 'list'
    else
      flash[:warning] = 'The next action was not added. Please try again.'
      redirect_to :controller => 'todo', :action => 'list'
    end
    
    rescue
      if request.xhr? # be sure to include an error.rjs
        render :action => 'error'
      else
        flash[:warning] = 'An error occurred on the server.'
        redirect_to :controller => 'todo', :action => 'list'
      end
  end
  
  # Toggles the 'done' status of the action
  #
  def toggle_check
    self.init

    @item = check_user_return_item
    @item.toggle!('done')
    @item.completed = Time.now() # For some reason, the before_save in todo.rb stopped working
    @saved = @item.save
    if @saved
      @down_count = Todo.find(:all, :conditions => ["todos.user_id = ? and todos.done = ? and todos.context_id IN (?)", @user.id, false, @item.context_id]).size.to_s
      @done_count = Todo.find(:all, :conditions => ["todos.user_id = ? and todos.done = ? and todos.context_id IN (?)", @user.id, true, @item.context_id]).size.to_s
    end
    return if request.xhr?

    if @saved
      flash[:notice]  = "The action <strong>'#{@item.description}'</strong> was marked as <strong>#{@item.done? ? 'complete' : 'incomplete' }</strong>"
    else
      flash[:notice]  = "The action <strong>'#{@item.description}'</strong> was NOT marked as <strong>#{@item.done? ? 'complete' : 'incomplete' } due to an error on the server.</strong>"
    end
    redirect_to :action => "list"
  end

  # Edit the details of the context
  #
  def update
    self.init
    check_user_set_context
    @context.attributes = params["context"]
    @context.name = deurlize(@context.name)
    if @context.save
      render :partial => 'context_listing', :object => @context
    else
      flash[:warning] = "Couldn't update new context"
      render :text => ""
    end
  end

  # Fairly self-explanatory; deletes the context
  # If the context contains actions, you'll get a warning dialogue.
  # If you choose to go ahead, any actions in the context will also be deleted.
  def destroy
    check_user_set_context
    if @context.destroy
      render_text ""
    else
      flash[:warning] = "Couldn't delete context \"#{@context.name}\""
      redirect_to( :controller => "context", :action => "list" )
    end
  end

  # Methods for changing the sort order of the contexts in the list
  #
  def order
    params["list-contexts"].each_with_index do |id, position|
      if check_user_matches_context_user(id)
        Context.update(id, :position => position + 1)
      end
    end
    render :nothing => true
  end
  
  protected

    def check_user_set_context
      if params["name"]
        @context = Context.find_by_name_and_user_id(deurlize(params["name"]), @user.id)
      elsif params['id']
        @context = Context.find_by_id_and_user_id(params["id"], @user.id)
      else
        redirect_to(:controller => "context", :action => "list" )
      end
      if @user == @context.user
        return @context
      else
        @context = nil # Should be nil anyway.
        flash[:warning] = "Item and session user mis-match: #{@context.user_id} and #{@user.id}!"
        render_text ""
      end
    end

    def check_user_matches_context_user(id)
       @context = Context.find_by_id_and_user_id(id, @user.id)
       if @user == @context.user
         return @context
       else
         @context = nil
         flash[:warning] = "Project and session user mis-match: #{@context.user_id} and #{@user.id}!"
         render_text ""
       end
    end
    
    def check_user_return_item
      item = Todo.find( params['id'] )
      if @user == item.user
        return item
      else
        flash[:warning] = "Item and session user mis-match: #{item.user.name} and #{@user.name}!"
        render_text ""
      end
    end
     
    def init
      @source_view = params['_source_view'] || 'context'
      # If we exclude completed projects, then we can't display them in the sidebar
      # if the user sets the preference for them to be shown
      # @projects = @user.projects.reject { |x| x.completed? }
      @projects = @user.projects
      @contexts = @user.contexts
      @todos = @user.todos
      @done = Todo.find(:all, :conditions => ["todos.user_id = ? and todos.done = ?", @user.id, true], :include => [:project], :order => "completed DESC")
      init_not_done_counts
    end

    def init_todos
      check_user_set_context
      @done = @context.done_todos
      # @not_done_todos = @context.not_done_todos
      # TODO: Temporarily doing this search manually until I can work out a way
      # to do the same thing using not_done_todos acts_as_todo_container method
      # Hides actions in hidden projects from context.
      @not_done_todos = Todo.find(:all, 
            :conditions => ["todos.context_id = ? and todos.done = ? and todos.type = ? and (projects.state != ? or todos.project_id is ?)", @context.id, false, "Immediate", "hidden", nil],
            :order => "todos.due IS NULL, todos.due ASC, todos.created_at ASC",
            :include => [:project])
      @count = @not_done_todos.size
    end

end
