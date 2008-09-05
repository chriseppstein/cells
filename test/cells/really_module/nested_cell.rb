module NestedCell; end


module ReallyModule

  class NestedCell < Cell::Base
    def happy_state
    end
    def unhappy_state
      redirect_to :simple, :two_templates_state
    end
  end
  
end
