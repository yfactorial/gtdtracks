module TodosHelper

  require 'users_controller'
  # Counts the number of uncompleted items in the specified context
  #
  def count_items(context)
    count = Todo.find_all("done=0 AND context_id=#{context.id}").length
  end

  def form_remote_tag_edit_todo( item, &block )
    form_tag( todo_path(item), {:method => :put, :id => dom_id(item, 'form'), :class => "edit_todo_form inline-form" }, &block )
    apply_behavior 'form.edit_todo_form', make_remote_form(:method => :put), :prevent_default => true
  end
  
  def remote_delete_icon(item)
    str = link_to( image_tag("blank.png", :title =>"Delete action", :class=>"delete_item"),
                   todo_path(item),
                   :class => "icon delete_icon", :title => "delete the action '#{item.description}'")
    apply_behavior '.item-container a.delete_icon:click', :prevent_default => true do |page|
       page << "if (confirm('Are you sure that you want to ' + this.title + '?')) {"
       page << "  new Ajax.Request(this.href, { asynchronous : true, evalScripts : true, method : 'delete', parameters : { '_source_view' : '#{@source_view}' }})"
       page << "}"
    end
    str
  end
  
  def remote_edit_icon(item)
    if !item.completed?
      str = link_to( image_tag_for_edit(item),
                      edit_todo_path(item),
                      :class => "icon edit_icon")
      apply_behavior '.item-container a.edit_icon:click', :prevent_default => true do |page|
        page << "new Ajax.Request(this.href, { asynchronous : true, evalScripts : true, method : 'get', parameters : { '_source_view' : '#{@source_view}' }, onLoading: function(request){ Effect.Pulsate(this)}});"
      end
    else
      str = '<a class="icon">' + image_tag("blank.png") + "</a> "
    end
    str
  end
  
  def remote_toggle_checkbox(item)
    str = check_box_tag('item_id', toggle_check_todo_path(item), item.completed?, :class => 'item-checkbox')
    apply_behavior '.item-container input.item-checkbox:click',
                   remote_function(:url => javascript_variable('this.value'),
                                   :with => "{ method : 'post', _source_view : '#{@source_view}' }")
    str
  end
  
  def date_span(item)
    if item.completed?
      "<span class=\"grey\">#{format_date( item.completed_at )}</span>"
    elsif item.deferred?
      show_date( item.show_from )
    else
      due_date( item.due ) 
    end    
  end
  
  def tag_list(item)
    item.tags.collect{|t| "<span class=\"tag\">" + link_to(t.name, :action => "tag", :id => t.name) + "</span>"}.join('')
  end
  
  def deferred_due_date(item)
    if item.deferred? && item.due
      "(action due on #{format_date(item.due)})"
    end
  end
  
  def project_and_context_links(item, parent_container_type)
    if item.completed?
       "(#{item.context.name}#{", " + item.project.name unless item.project.nil?})"
    else
      str = ''
      if (['project', 'tickler', 'tag'].include?(parent_container_type))
        str << item_link_to_context( item )
      end
      if (['context', 'tickler', 'tag'].include?(parent_container_type)) && item.project_id
        str << item_link_to_project( item )
      end
      str
    end
  end
    
  # Uses the 'staleness_starts' value from settings.yml (in days) to colour
  # the background of the action appropriately according to the age
  # of the creation date:
  # * l1: created more than 1 x staleness_starts, but < 2 x staleness_starts
  # * l2: created more than 2 x staleness_starts, but < 3 x staleness_starts
  # * l3: created more than 3 x staleness_starts
  #
  def staleness_class(item)
    if item.due || item.completed?
      return ""
    elsif item.created_at < (@user.prefs.staleness_starts * 3).days.ago.utc
      return " stale_l3"
    elsif item.created_at < (@user.prefs.staleness_starts * 2).days.ago.utc
      return " stale_l2"
    elsif item.created_at < (@user.prefs.staleness_starts).days.ago.utc
      return " stale_l1"
    else
      return ""
    end
  end

  # Check show_from date in comparison to today's date
  # Flag up date appropriately with a 'traffic light' colour code
  #
  def show_date(due)
    if due == nil
      return ""
    end

    days = days_from_today(due)
       
    case days
      # overdue or due very soon! sound the alarm!
      when -1000..-1
        "<a title='" + format_date(due) + "'><span class=\"red\">Shown on " + (days * -1).to_s + " days</span></a> "
      when 0
           "<a title='" + format_date(due) + "'><span class=\"amber\">Show Today</span></a> "
      when 1
           "<a title='" + format_date(due) + "'><span class=\"amber\">Show Tomorrow</span></a> "
      # due 2-7 days away
      when 2..7
      if @user.prefs.due_style == 1
        "<a title='" + format_date(due) + "'><span class=\"orange\">Show on " + due.strftime("%A") + "</span></a> "
      else
        "<a title='" + format_date(due) + "'><span class=\"orange\">Show in " + days.to_s + " days</span></a> "
      end
      # more than a week away - relax
      else
        "<a title='" + format_date(due) + "'><span class=\"green\">Show in " + days.to_s + " days</span></a> "
    end
  end
  
  def calendar_setup( input_field )
    date_format = @user.prefs.date_format
    week_starts = @user.prefs.week_starts
    str = "Calendar.setup({ ifFormat:\"#{date_format}\""
    str << ",firstDay:#{week_starts},showOthers:true,range:[2004, 2010]"
    str << ",step:1,inputField:\"" + input_field + "\",cache:true,align:\"TR\" })\n"
    javascript_tag str
  end
  
  def item_container_id
    return "tickler-items" if source_view_is :deferred
    if source_view_is :project
      return "p#{@item.project_id}" if @item.active?
      return "tickler" if @item.deferred?
    end
    return "c#{@item.context_id}"
  end

  def should_show_new_item
    return true if source_view_is(:deferred) && @item.deferred?
    return true if source_view_is(:project) && @item.project.hidden? && @item.project_hidden?
    return true if source_view_is(:project) && @item.deferred?
    return true if !source_view_is(:deferred) && @item.active?
    return false
  end
  
  def parent_container_type
    return 'tickler' if source_view_is :deferred
    return 'project' if source_view_is :project
    return 'context'
  end
  
  def empty_container_msg_div_id
    return "tickler-empty-nd" if source_view_is(:project) && @item.deferred?
    return "p#{@item.project_id}empty-nd" if source_view_is :project
    return "tickler-empty-nd" if source_view_is :deferred
    return "c#{@item.context_id}empty-nd"
  end
  
  def project_names_for_autocomplete
     array_or_string_for_javascript( ['None'] + @projects.collect{|p| escape_javascript(p.name) } )
  end
  
  def context_names_for_autocomplete
     return array_or_string_for_javascript(['Create a new context']) if @contexts.empty?
     array_or_string_for_javascript( @contexts.collect{|c| escape_javascript(c.name) } )
  end
    
  private
  
  def image_tag_for_delete
    image_tag("blank.png", :title =>"Delete action", :class=>"delete_item")
  end
  
  def image_tag_for_edit(item)
    image_tag("blank.png", :title =>"Edit action", :class=>"edit_item", :id=> dom_id(item, 'edit_icon'))
  end
  
end
