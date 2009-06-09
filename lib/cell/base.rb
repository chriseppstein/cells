module Cell
  # == Basic overview
  #
  # A Cell is the central notion of the cells plugin.  A cell acts as a
  # lightweight controller in the sense that it will assign variables and
  # render a view.  Cells can be rendered from other cells as well as from
  # regular controllers and views (see ActionView::Base#render_cell and
  # ControllerMethods#render_cell_to_string)
  #
  # == A render_cell() cycle
  #
  # A typical <tt>render_cell</tt> state rendering cycle looks like this:
  #   render_cell :blog, :newest_article, {...}
  # - an instance of the class <tt>BlogCell</tt> is created, and a hash containing
  #   arbitrary parameters is passed
  # - the <em>state method</em> <tt>newest_article</tt> is executed and assigns instance
  #   variables to be used in the view
  # - if the method returns a string, the cycle ends, rendering the string
  # - otherwise, the corresponding <em>state view</em> is searched.
  #   Usually the cell will first look for a view template in
  #   <tt>app/cells/blog/newest_article.html. [erb|haml|...]</tt>
  # - after the view has been found, it is rendered and returned
  #
  # It is common to simply return <tt>nil</tt> in state methods to advice the cell to
  # render the corresponding template.
  #
  # == Design Principles
  # A cell is a completely autonomous object and it should not know or have to know
  # from what controller it is being rendered.  For this reason, the controller's
  # instance variables and params hash are not directly available from the cell or
  # its views. This is not a bug, this is a feature!  It means cells are truly
  # reusable components which can be plugged in at any point in your application
  # without having to think about what information is available at that point.
  # When rendering a cell, you can explicitly pass variables to the cell in the
  # extra opts argument hash, just like you would pass locals in partials.
  # This hash is then available inside the cell as the params method.
  #
  # == Directory hierarchy
  #
  # To get started creating your own cells, you can simply create a new directory
  # structure under your <tt>app</tt> directory called <tt>cells</tt>.  Cells are
  # ruby classes which end in the name Cell.  So for example, if you have a
  # cell which manages all user information, it would be called <tt>UserCell</tt>.
  # A cell which manages a shopping cart could be called <tt>ShoppingCartCell</tt>.
  #
  # The directory structure of this example would look like this:
  #   app/
  #     models/
  #       ..
  #     views/
  #       ..
  #     helpers/
  #       application_helper.rb
  #       product_helper.rb
  #       ..
  #     controllers/
  #       ..
  #     cells/
  #       shopping_cart_cell.rb
  #       shopping_cart/
  #         status.html.erb
  #         product_list.html.erb
  #         empty_prompt.html.erb
  #       user_cell.rb
  #       user/
  #         login.html.erb
  #     ..
  #
  # The directory with the same name as the cell contains views for the
  # cell's <em>states</em>.  A state is an executed method along with a
  # rendered view, resulting in content. This means that states are to
  # cells as actions are to controllers, so each state has its own view.
  # The use of partials is deprecated with cells, it is better to just
  # render a different state on the same cell (which also works recursively).
  #
  # Anyway, <tt>render :partial </tt> in a cell view will work, if the
  # partial is contained in the cell's view directory.
  #
  # As can be seen above, Cells also can make use of helpers.  All Cells
  # include ApplicationHelper by default, but you can add additional helpers
  # as well with the Cell::Base.helper class method:
  #   class ShoppingCartCell < Cell::Base
  #     helper :product
  #     ...
  #   end
  #
  # This will make the <tt>ProductHelper</tt> from <tt>app/helpers/product_helper.rb</tt>
  # available from all state views from our <tt>ShoppingCartCell</tt>.
  #
  # == Cell inheritance
  #
  # Unlike controllers, Cells can form a class hierarchy.  When a cell class
  # is inherited by another cell class, its states are inherited as regular
  # methods are, but also its views are inherited.  Whenever a view is looked up,
  # the view finder first looks for a file in the directory belonging to the
  # current cell class, but if this is not found in the application or any
  # engine, the superclass' directory is checked.  This continues all the
  # way up until it stops at Cell::Base.
  #
  # For instance, when you have two cells:
  #   class MenuCell < Cell::Base
  #     def show
  #     end
  #
  #     def edit
  #     end
  #   end
  #
  #   class MainMenuCell < MenuCell
  #     .. # no need to redefine show/edit if they do the same!
  #   end
  # and the following directory structure in <tt>app/cells</tt>:
  #   app/cells/
  #     menu/
  #       show.html.erb
  #       edit.html.erb
  #     main_menu/
  #       show.html.erb
  # then when you call
  #   render_cell :main_menu, :show
  # the main menu specific show.html.erb (<tt>app/cells/main_menu/show.html.erb</tt>)
  # is rendered, but when you call
  #   render_cell :main_menu, :edit
  # cells notices that the main menu does not have a specific view for the
  # <tt>edit</tt> state, so it will render the view for the parent class,
  # <tt>app/cells/menu/edit.html.erb</tt>
  #
  #
  # == Gettext support
  #
  # Cells support gettext, just name your views accordingly. It works exactly equivalent
  # to controller views.
  #
  #   cells/user/user_form.html.erb
  #   cells/user/user_form_de.html.erb
  #
  # If gettext is set to DE_de, the latter view will be chosen.
  class Base
    NAME_SUFFIX = "_cell"
    # Backwards Compatibility support.
    include Compatibility
    attr_accessor :controller
    attr_accessor :state_name
    attr_reader :cell_name

    # Forgery protection for forms
    cattr_accessor :request_forgery_protection_token
    class_inheritable_accessor :allow_forgery_protection
    self.allow_forgery_protection = true


    def initialize(controller, cell_name=nil, options={})
      @controller = controller
      @cell_name  = cell_name || self.class.cell_name
      @opts       = options
      @render_opts = nil
      @views = {}
      self.allow_forgery_protection = true
    end

    # Access the parameters passed to this cell.
    def params
      @opts
    end

    # Access the current controller's params hash.
    # Use of this method is not recommended!
    # It couples the Cell to the Controller from which it is rendered.
    # This will break caching and make your cell less re-usable.
    def controller_params
      @controller.params
    end

    # Access the session
    # Use of this method is not recommended!
    # It couples the Cell to the User for which it is rendered.
    # This will break caching and make your cell less re-usable.
    def session
      @controller.session
    end

    # Access the current request object.
    # Use of this method is not recommended!
    # It couples the Cell to the Request for which it is rendered.
    # This will break caching and make your cell less re-usable.
    def request
      @controller.request
    end

    # Render the current cell. With no options, or if not invoked,
    # the default render for the current state will be invoked.
    # Valid options:
    # :state - render the template associated with a different state -- does not execute that state.
    # :text - render a string as the contents of the cell.
    # :nothing - when set to true, renders nil. This makes it possible
    #            for a cell to decide to not render and allow the calling template to chain cells
    #            together with short circuiting like so:
    #            render_cell(:article, :recent) || render_cell(:blog_post, :recent)
    # :layout - when set to true, the content will be placed into a layout named "layout" in the cell directory,
    #           when a string, the name represents a layout template in the app/cells/layouts directory.
    def render(options = {})
      raise double_render! if @render_opts
      @render_opts = options
    end

    # Redirects to the another state of the current cell:
    # redirect_to :alternate_state, :some => :options
    #
    # Or to another cell altogether.
    # redirect_to :another_cell, :some_state, :some => :options
    def redirect_to(*arguments)
      opts = arguments.extract_options!
      if arguments.size < 2
        arguments.unshift cell_name
      end
      arguments << opts
      render :text => @controller.send(:instance_variable_get, "@template").render_cell(*arguments)
    end

    include ActionController::Helpers
    include ActionController::RequestForgeryProtection

    helper ApplicationHelper

    # Declare a controller method as a helper.  For example,
    #   helper_method :link_to
    #   def link_to(name, options) ... end
    # makes the link_to controller method available in the view.
    def self.helper_method(*methods)
      methods.flatten.each do |method|
        master_helper_module.module_eval <<-end_eval
          def #{method}(*args, &block)
            @cell.send(%(#{method}), *args, &block)
          end
        end_eval
      end
    end

    class_inheritable_accessor :cache_states

    def self.caches(*states)
      options = states.extract_options!
      self.cache_states ||= {}
      states.inject(cache_states) do |mem, var|
        mem[var] = options[:if] || true
        mem
      end
    end

    # Creates a cell instance of the class <tt>name</tt>Cell, passing through
    # <tt>opts</tt>.
    def self.create_cell_for(controller, name, opts={})
      class_from_cell_name(name).new(controller, name, opts)
    end

    protected
    # Empty method.  Returns nil.  You can override this method
    # in individual cell classes if you want them to determine the
    # view file dynamically.
    #
    # If a view filename is returned here, we assume it really exists
    # and don't invoke the superclass view finding chain.
    def view_for_state(state)
      nil
    end

    # Render the given state.  You can pass the name as either a symbol or
    # a string.
    def render_state(state)
      @cell = self
      state = state.to_s
      self.state_name = state

      @state_return_value = send(state)

      render_to_string(state)
    end

    # Render the view belonging to the given state.  This can be called
    # from other states as well, when you need to render the same view file
    # from two states.
    def render_view_for_state(state, options = {})
      begin
        # path that is passed to finder.path_and_extension
        action_view_template(state).render(options.merge(:file => state.to_s, :use_full_path => true))
      rescue ActionView::MissingTemplate
        ### TODO: introduce error method.
        if RAILS_ENV == "development"
          return "ATTENTION: cell view for #{cell_name}##{state} is not readable/existing."
        elsif RAILS_ENV == "test"
          raise
        else
          warn "ATTENTION: cell view for #{cell_name}##{state} is not readable/existing."
          return nil
        end
      end
    end

    def action_view_template(state)
      @views[state.to_s] ||= begin
        view_class  = Class.new(ActionView::Base)

        # We cheat a little bit by providing the view class with a known-good views dir
        returning(view_class.new("#{RAILS_ROOT}/app/views", {}, @controller)) do |action_view|
          # Now override the finder in the view_class with our own (we can't use Rails' finder because it's braindead)
          add_cell_paths_to_finder(action_view.send(:instance_variable_get, '@finder'))
          action_view.send(:instance_variable_set, '@template', action_view)
          action_view.send(:instance_variable_set, '@cell', self)
          action_view.extend(Cell::View)
          # Make helpers and instance vars available
          include_helpers_in_class(view_class)
          clone_ivars_to(action_view)
        end
      end
    end

    def render_to_string(state)
      @render_opts ||= {}
      if layout = @render_opts.delete(:layout)
        render_layout(layout, state)
      elsif @render_opts[:text]
        @render_opts[:text].to_s
      elsif s = @render_opts.delete(:state)
        render_view_for_state(s, @render_opts)
      elsif @render_opts[:nothing]
        nil
      else
        render_view_for_state(view_for_state(state) || state, @render_opts)
      end
    end

    def render_layout(layout, state)
      content = render_to_string(state)
      avt = action_view_template(state)
      avt.instance_variable_set("@content_for_layout", content)
      layout = (layout == true) ? "#{self.cell_name}/layout" : "layouts/#{layout}"
      avt.render(:file => layout, :use_full_path => true)
    end

    def double_render!
      ActionController::DoubleRenderError.new(%q{render or redirect_to was called multiple times in this state. Please note that you may only call render/redirect_to at most once per state. Also note that neither render nor redirect_to terminate execution of the state, so if you want to exit after rendering, you need to do something like "render(...) and return"})
    end

    # Get the name of this cell's class as an underscored string,
    # with _cell removed.
    #
    # Example:
    #  UserCell.cell_name
    #  => "user"
    def self.cell_name
      self.name.underscore.sub(/#{NAME_SUFFIX}/, '')
    end

    # Given a cell name, find the class that belongs to it.
    #
    # Example:
    # Cell::Base.class_from_cell_name(:user)
    # => UserCell
    def self.class_from_cell_name(cell_name)
      "#{cell_name}#{NAME_SUFFIX}".classify.constantize
    end

    def add_cell_paths_to_finder(finder)
      paths = []
      possible_cell_paths.each do |cell_path|
        possible_cell_subdirectories.each do |subdir|
          paths << File.join(cell_path, subdir)
        end
        paths << cell_path
      end
      finder.prepend_view_path paths
    end

    # returns a list of subdirectories in order that should be searched under app/cells
    # this is derived from the cell names of the current cell and all
    # its superclasses up to Cell::Base. and then adds 'layouts' and 'shared'.
    def possible_cell_subdirectories
      @possible_cell_subdirectories ||= begin
        resolve_cell = self.class
        subdirs = []
        while resolve_cell != Cell::Base
          subdirs << resolve_cell.to_s.underscore[0..-6]
          resolve_cell = resolve_cell.superclass
        end
        subdirs + ["shared"]
      end
    end

    # To see if the template can be found, make list of possible cells paths, according
    # to:
    # If Engines loaded: then append paths in order so that more recently started plugins
    # will take priority and RAILS_ROOT/app/cells with highest prio.
    # Engines not-loaded: then only RAILS_ROOT/app/cells
    def possible_cell_paths
      if Cell.engines_available?
        Rails.plugins.by_precedence.map {|plugin| File.join(plugin.directory, Cell::CELL_DIR)}.unshift(File.join(RAILS_ROOT, Cell::CELL_DIR))
      else
        [File.join(RAILS_ROOT, Cell::CELL_DIR)]
      end
    end

    # When passed a copy of the ActionView::Base class, it
    # will mix in all helper classes for this cell in that class.
    def include_helpers_in_class(view_klass)
      view_klass.send(:include, self.class.master_helper_module)
    end

    ### template variables assigning --------------------------------------------

    # Clone the instance variables on the current cell to an ActionView object.
    def clone_ivars_to(obj)
      (self.instance_variables - ivars_to_ignore).each do |var|
        obj.instance_variable_set(var, instance_variable_get(var))
      end
    end

    # Defines the instance variables that Cell::Base#clone_ivars_to should
    # <em>not</em> copy.
    def ivars_to_ignore
      ['@controller', '@_already_rendered']
    end

  end
end
