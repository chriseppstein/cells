module Cell
  # Backwards Compatibility support.
  # In your existing cell you can do this to avoid having to upgrade it.
  # class MyOldCell < Cell::Base
  #   legacy_cell
  #   ...
  # end
  # TODO: This needs real world testing -- I don't have any legacy cells.
  module Compatibility
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def legacy_cell
        self.send :include, InstanceMethods
        alias_method_chain :render_to_string, :legacy_support
        [:render_state, :render_view_for_state].each do |pvt_methd|
          public pvt_methd
        end
      end
    end

    module InstanceMethods
      def render_to_string_with_legacy_support(state)
        if @render_opts.nil? && !@state_return_value.nil?
          @render_opts = {:text => @state_return_value.to_s}
        end
        render_to_string_without_legacy_support(state)
      end
      def params
        @opts
      end
    end
  end
end