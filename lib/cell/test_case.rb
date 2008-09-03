require 'active_support/test_case'

module Cell
  class NonInferrableCellError < Exception
    def initialize(name)
      @name = name
      super "Unable to determine the cell to test from #{name}. " +
        "You'll need to specify it using 'tests YourCell' in your " +
        "test case definition. This could mean that #{inferred_cell_name} does not exist " +
        "or it contains syntax errors"
    end

    def inferred_cell_name
      @name.sub(/Test$/, '')
    end
  end

  class TestCase < ActiveSupport::TestCase
    setup :setup_controller

    @@cell_class = nil
    
    def get(state, params={})
      cell = Cell::Base.create_cell_for(@controller, self.class.cell_class.name.underscore, params)
      @controller.response.body = cell.render_state(state)
    end

    class << self
      def tests(cell_class)
        self.cell_class = cell_class
      end

      def cell_class=(new_class)
        write_inheritable_attribute(:cell_class, new_class)
      end

      def cell_class
        if current_cell_class = read_inheritable_attribute(:cell_class)
          current_cell_class
        else
          self.cell_class = determine_default_cell_class(name)
        end
      end

      def determine_default_cell_class(name)
        name.sub(/Test$/, '').constantize
      rescue NameError
        raise NonInferrableControllerError.new(name)
      end
    end

    def setup_controller
      @controller = TestController.new
    end
    
    class TestController < ActionController::Base
      attr_accessor :request, :response

      def initialize
        @request = ActionController::TestRequest.new
        @response = ActionController::TestResponse.new
      end
    end

 end
end