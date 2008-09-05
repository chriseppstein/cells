class TestCell < Cell::Base

  def view_for_state(state)    
    RAILS_ROOT+"/vendor/plugins/cells/test/views/#{state}.html.erb"
  end

  def direct_output
    render :text => "<h9>this state method doesn't render a template but returns a string, which is great!</h9>"
  end

  def rendering_state
    @instance_variable_one = "yeah"
  end

  def another_rendering_state
    @instance_variable_one = "go"
  end

  def setting_state
    @reset_me = '<p id="ho">ho</p>'
  end

  def reset_state
  end

  def state_with_link_to
  end

  def state_with_not_included_helper_method
  end
  
end
