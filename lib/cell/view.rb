module Cell
  module View
    def params
      @cell.params
    end
    def request
      @cell.request
    end
    def session
      @cell.session
    end
    def controller_params
      @cell.controller_params
    end
  end
end