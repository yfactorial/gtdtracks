class ContextsController < ApplicationController

  helper :todos

  before_filter :init, :except => [:index, :create, :destroy, :order]
  before_filter :init_todos, :only => :show
  before_filter :set_context_from_params, :only => [:update, :destroy]
  skip_before_filter :login_required, :only => [:index]
  prepend_before_filter :login_or_feed_token_required, :only => [:index]
  session :off, :only => :index, :if => Proc.new { |req| ['rss','atom','txt'].include?(req.parameters[:format]) }

  def index
    @contexts = current_user.contexts(true) #true is passed here to force an immediate load so that size and empty? checks later don't result in separate SQL queries
    init_not_done_counts(['context'])
    respond_to do |format|
      format.html &render_contexts_html
      format.xml  { render :xml => @contexts.to_xml( :except => :user_id ) }
      format.rss  &render_contexts_rss_feed
      format.atom &render_contexts_atom_feed
      format.text { render :action => 'index_text', :layout => false, :content_type => Mime::TEXT }
    end
  end
  
  def show
    if (@context.nil?)
      respond_to do |format|
        format.html { render :text => 'Context not found', :status => 404 }
        format.xml  { render :xml => '<error>Context not found</error>', :status => 404 }
      end
    else
      @page_title = "TRACKS::Context: #{@context.name}"
      respond_to do |format|
        format.html
        format.xml  { render :xml => @context.to_xml( :except => :user_id ) }
      end
    end
  end
  
  # Example XML usage: curl -H 'Accept: application/xml' -H 'Content-Type: application/xml'
  #                    -u username:password
  #                    -d '<request><context><name>new context_name</name></context></request>'
  #                    http://our.tracks.host/contexts
  #
  def create
    if params[:format] == 'application/xml' && params['exception']
      render_failure "Expected post format is valid xml like so: <request><context><name>context name</name></context></request>.", 400
      return
    end
    @context = current_user.contexts.build
    params_are_invalid = true
    if (params['context'] || (params['request'] && params['request']['context']))
      @context.attributes = params['context'] || params['request']['context']
      params_are_invalid = false
    end
    @saved = @context.save
    @context_not_done_counts = { @context.id => 0 }
    respond_to do |format|
      format.js do
        @down_count = current_user.contexts.size
      end
      format.xml do
        if @context.new_record? && params_are_invalid
          render_failure "Expected post format is valid xml like so: <request><context><name>context name</name></context></request>.", 400
        elsif @context.new_record?
          render_failure @context.errors.to_xml, 409
        else
          head :created, :location => context_url(@context)
        end
       end
    end
  end
  
  # Edit the details of the context
  #
  def update
    params['context'] ||= {}
    success_text = if params['field'] == 'name' && params['value']
      params['context']['id'] = params['id'] 
      params['context']['name'] = params['value'] 
    end
    @context.attributes = params["context"]
    if @context.save
      if params['wants_render']
        render
      else
        render :text => success_text || 'Success'
      end
    else
      notify :warning, "Couldn't update new context"
      render :text => ""
    end
  end

  # Fairly self-explanatory; deletes the context
  # If the context contains actions, you'll get a warning dialogue.
  # If you choose to go ahead, any actions in the context will also be deleted.
  def destroy
    @context.destroy
    respond_to do |format|
      format.js { @down_count = current_user.contexts.size }
      format.xml { render :text => "Deleted context #{@context.name}" }
    end
  end

  # Methods for changing the sort order of the contexts in the list
  #
  def order
    params["list-contexts"].each_with_index do |id, position|
      current_user.contexts.update(id, :position => position + 1)
    end
    render :nothing => true
  end
  
  protected

    def render_contexts_html
      lambda do
        @page_title = "TRACKS::List Contexts"
        @no_contexts = @contexts.empty?
        @count = @contexts.size
        render
      end
    end

    def render_contexts_rss_feed
      lambda do
        render_rss_feed_for @contexts, :feed => feed_options,
                                       :item => { :description => lambda { |c| c.summary(count_undone_todos_phrase(c)) } }
      end
    end

    def render_contexts_atom_feed
      lambda do
        render_atom_feed_for @contexts, :feed => feed_options,
                                        :item => { :description => lambda { |c| c.summary(count_undone_todos_phrase(c)) },
                                                   :author => lambda { |c| nil } }
      end
    end
    
    def feed_options
      Context.feed_options(current_user)
    end

    def set_context_from_params
      @context = current_user.contexts.find_by_params(params)
    rescue
      @context = nil
    end
     
    def init
      @source_view = params['_source_view'] || 'context'
      init_data_for_sidebar
    end

    def init_todos
      set_context_from_params
      unless @context.nil?
        @context.todos.with_scope :find => { :include => [:project, :tags] } do
          @done = @context.done_todos
        end
        # @not_done_todos = @context.not_done_todos
        # TODO: Temporarily doing this search manually until I can work out a way
        # to do the same thing using not_done_todos acts_as_todo_container method
        # Hides actions in hidden projects from context.
        @not_done_todos = @context.todos.find(:all, :conditions => ['todos.state = ?', 'active'], :order => "todos.due IS NULL, todos.due ASC, todos.created_at ASC", :include => [:project, :tags])
        @count = @not_done_todos.size
        @default_project_context_name_map = build_default_project_context_name_map(@projects).to_json
      end
    end

end
