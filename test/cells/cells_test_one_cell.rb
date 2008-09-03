class CellsTestOneCell < Cell::Base

  caches :super_state, :instance_view, :if => :ggg
  def super_state
    @my_class = self.class.to_s
    return
  end

  def instance_view
  end

  def view_for_state(state)
    if state.to_s == 'instance_view'
      return File.dirname(__FILE__) + '/cells_test_one/renamed_instance_view.html.erb'
    end
  end

  def state_with_no_view
  end

end
