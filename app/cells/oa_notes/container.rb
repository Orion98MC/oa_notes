module OANotes
  begin;OANotes::Authorizations.instance_methods;rescue;module Authorizations;end;end
  
  class Container < OAWidget::Base   
    include OANotes::Authorizations
    
    # Set adapter defaults
    ['update?', 'delete?', 'create?', 'toogle_mark?'].each do |method|
      unless OANotes::Authorizations.instance_methods.include?(method)
        OANotes::Authorizations::module_eval {define_method(method.to_sym){true}}
      end
    end # each method

    PRESERVING_PARAMS = [:search_text, :view, :sort, :per_page]
    PRESERVING_PARAMS.each do |p|
      attr_accessor p
    end
    
    has_widgets do |top|
      heartbeatWidget = OAWidget::Heartbeat.new("#{top.name}-heartbeat",  :preserve => PRESERVING_PARAMS)
      anchorsWidget   = OAWidget::Anchors.new("#{top.name}-anchors",      :preserve => PRESERVING_PARAMS)
      
      searchWidget    = OANotes::Search.new("#{top.name}-search",   :preserve => PRESERVING_PARAMS)
      filtersWidget   = OANotes::Filters.new("#{top.name}-filters", :preserve => PRESERVING_PARAMS)
      contentWidget   = OANotes::Content.new("#{top.name}-content", :preserve => PRESERVING_PARAMS)
      formWidget      = OANotes::Form.new("#{top.name}-form",       :preserve => PRESERVING_PARAMS)
      
      top << heartbeatWidget
      top << searchWidget     unless top.hidden?(:search)
      top << anchorsWidget    if top.save?
      top << filtersWidget    unless top.hidden?(:filters)
      top << contentWidget    unless top.hidden?(:content)
      top << formWidget       if top.create?

      top.respond_to_event :params_changed,   :with => :update_heartbeat, :on => heartbeatWidget.name
      top.respond_to_event :filters_changed,  :with => :update_heartbeat, :on => heartbeatWidget.name
      top.respond_to_event :filters_changed,  :with => :update_content,   :on => contentWidget.name
      top.respond_to_event :content_changed,  :with => :update_content,   :on => contentWidget.name
      top.respond_to_event :search,           :with => :update_content,   :on => contentWidget.name
      top.respond_to_event :edit,             :with => :edit,             :on => formWidget.name
    end
    
    def initialize(widget_id, options={}) 
      # 
      # Usage:
      # ------ 
      #  OANotes::Container.new("notes", OPTIONS)
      #
      #  OPTIONS: A hash with following options:
      #
      #  :notes => string (ex: :notes => "@intervention.notes" or :notes => "MyNote")
      #  :save => lambda {|config| ...save config hash... } 
      #
      # scopes:
      #  :search => a named scope of the model used for searches, it receives self as parameter when called.
      #  :views => [['My scope 1', :scope1], ...] an array of named scopes for view filter 
      #  :sorts => [['My filter 1', :filter1], ...] an array of named scopes for the sorting filter
      #
      # marks:
      #  :has_markings? => true or false (default: false)
      #  :toogle_mark! => a model method name, the method is called when the user marks or unmarks a note and is passed the note as parameter
      #  :marked? => a model method name, the method is called with note as parameter. Must return true or false
      #
      # customizations:
      #  :hide => [:search, :filters, :content, :form]
      #  :pages => [['5', 5], ['Many', 100], ...] an array of per_pages for the per_page filter
      #  :note_partial => 'partial/path' the partial to use when rendering notes. it is passed a :note locals
      #  :form_partial => 'partial/path' the partial to use when rendering the form. it is passed a :note locals
      #  :title => string, this is the title to be displayed in the widget's title bar
      #
      # Authorizations:
      # ===============
      # By default, all is allowed, to allow/forbid delete/create/update/mark notes you can create a Authorizations module in OANote module
      # Put it in app/cells/oa_notes.rb, here is an example:
      #
      # module OANotes
      #   module Authorizations
      #     def delete?(note)
      #       can? :delete, note
      #     end
      #
      #     def create?(note)
      #       can? :create, note.class
      #     end
      #
      #     def update?(note)
      #       can? :update, note
      #     end
      #     
      #     def toogle_mark?(note)
      #       can? :toogle_mark, note
      #     end
      #   end
      # end
      #
      # Example:
      # ========
      # class DashboardController < ApplicationController
      #   include Apotomo::Rails::ControllerMethods
      #   ...
      #   has_widgets do |root|
      #     root < OANotes::Container.new('notes', 
      #       :title => 'My notes', 
      #       :notes => "@current_user.notes", 
      #       :search => :search, 
      #       :note_partial => 'partials/user_note',
      #     )
      #   end
      #   
      #   def show
      #   end
      #   ...
      # end
      #
      # in views/dashboard/show.haml.html:
      # ...
      #   = render_widget 'notes'
      # ...
      
      # saved options
      @saved_options = {}
      # saveable attributes
      ([:hide, :marked?, :toogle_mark!, :note_partial, :form_partial, :views, :sorts, :pages, :search, :has_markings?, :title, :notes] << PRESERVING_PARAMS).each do |saved_attribute|
        @saved_options[saved_attribute] = options[saved_attribute] if options.include?(saved_attribute)
      end

      @notes = options.delete(:notes) #string
      @save = options.delete(:save) #lambda
      @hide = options.delete(:hide) #array
      @search = options.delete(:search) #scope
      @has_markings = options.delete(:has_markings?) #boolean
      @marked = options.delete(:marked?) #method name
      @toogle_mark = options.delete(:toogle_mark!) #method name
      @note_partial = options.delete(:note_partial) #string
      @form_partial = options.delete(:form_partial) #string
      @views = options.delete(:views) #array of scopes
      @sorts = options.delete(:sorts) #array of scopes
      @pages = options.delete(:pages) #array of per_page integer
      @title = options.delete(:title) #string
      
      # params that could be passed as defaults
      @view = options.delete(:view)
      @sort = options.delete(:sort)
      @per_page = options.delete(:per_page)
      @search_text = options.delete(:search_text)
      
      # Default values for preserved params
      @view ||= 0 unless @views.blank?
      @sort ||= 0 unless @sorts.blank?
      @per_page ||= self.class.per_page
      
      super(widget_id, :container, options)
    end
    
    def container
      get_preserved_params
      render
    end
    
    def update_container
      get_preserved_params
      replace :view => 'container'
    end
    
    #pragma mark -
    #pragma mark accessors
    
    def hidden?(part)
      @hide ||= []
      @hide.include?(part.to_sym)
    end

    def views; @views; end
    def sorts; @sorts; end
    def pages; @pages; end
    def per_page; @per_page; end
    def note_partial; @note_partial; end
    def form_partial; @form_partial; end
    def has_markings?; @has_markings; end
    
    def filters
      f = []
      f << @views[@view.to_i].last unless @views.blank? && @view.blank?
      f << @sorts[@sort.to_i].last unless @sorts.blank? && @sort.blank?
      (f - [nil]).flatten
    end
    
    def note_scope
      @note.blank? ? "Note" : @notes
    end
    
    def eval_note
      eval note_scope
    end
        
    def all_notes(more=nil)
      scopes = []
      scopes << filters
      if more.nil?
        scopes << @search unless search_text.blank?
      else
        scopes << more unless more.nil?
      end
      scopes.flatten!
      scopes -= [nil]

      scopes_to_eval = [note_scope]
      scopes.each do |scope|
        scopes_to_eval << "send(:#{scope}, self)"
      end
      RAILS_DEFAULT_LOGGER.debug("all_notes: #{scopes_to_eval.join('.')}")
      debugger
      eval scopes_to_eval.join('.')
    end
    
    def marked?(note)
      note.send(@marked.to_sym)
    end
    
    def toogle_mark!(note)
      note.send(@toogle_mark.to_sym)
    end
    
    def save?
      !@save.nil?
    end
    
    def save
      @save.call(saved_state)
    end
    
    
    private
    def get_preserved_params
      PRESERVING_PARAMS.each do |p|
        self.instance_variable_set("@#{p.to_s}", param(p.to_sym)) if param(p.to_sym)
      end
    end
    
    def self.per_page; 5; end
    
    def saved_state
      widget_state = @saved_options
      widget_state.merge!(params)
      widget_state.delete(:save)
      ["event","action","authenticity_token","type","controller","source","_"].each do |k|
        widget_state.delete(k.to_sym)
        widget_state.delete(k)
      end
      widget_state[:widget_class] = self.class.to_s
      widget_state[:widget_name] = name
      
      clean_states = {}
      widget_state.each do |key, value|
        clean_states[key.to_sym] = value
      end
      clean_states
    end
    
  end
end