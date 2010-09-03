module OANotes
  # Set a default adapter for the "Note" model
  begin;OANotes::Adapter.instance_methods;rescue;module Adapter;end;end
  
  class Container < OAWidget::Base   
    include OANotes::Adapter
    
    # Set adapter defaults
    unless OANotes::Adapter.instance_methods.include?('note_class')
      OANotes::Adapter::module_eval {define_method('note_class'.to_sym){Note}}
    end
    ['editable?', 'deletable?', 'creatable?'].each do |method|
      unless OANotes::Adapter.instance_methods.include?(method)
        OANotes::Adapter::module_eval {define_method(method.to_sym){true}}
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
      contentWidget   = OANotes::Content.new("#{top.name}-content", :preserve => PRESERVING_PARAMS, :details => top.details, :eval_options => top.eval_options)
      formWidget      = OANotes::Form.new("#{top.name}-form",       :preserve => PRESERVING_PARAMS, :form => top.form, :eval_options => top.eval_options)
      
      top << heartbeatWidget
      top << searchWidget     unless top.hidden?(:search)
      top << anchorsWidget    if top.saveable?
      top << filtersWidget    unless top.hidden?(:filters)
      top << contentWidget    unless top.hidden?(:content)
      top << formWidget       if top.creatable?

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
      #  :hide => [:search, :filters, :content, :form]
      #  :scope => a named_scope for the model, this will be the default named scope for search, pagination etc...
      #  :search => a named scope for the model, this will be used to search
      #  :has_markings? => true or false (default: false)
      #  :toogle_mark! => a model method name, the method is called with note as attribute
      #  :marked? => a model method name, the method is called with note as attribute
      #  :views => [['My scope 1', :scope1], ...] an array of named scopes for view filter 
      #  :sorts => [['My filter 1', :filter1], ...] an array of named scopes for the sorting filter
      #  :pages => [['5', 5], ['Many', 100], ...] an array of per_pages for the per_page filter
      #  :details => a lambda or proc to be evaluated against the note to display the note content
      #  :form => a lambda or proc to be evaluated against the note and display the note form
      #  :eval_options => array of options to be evaluated before being called
      #  :title => string, this is the title to be displayed in the widget's title bar
      #  :save => lambda called when the user clicks on "save". It receives an argument, a hash containing the live configuration of the widget
      
      # saved options
      @saved_options = {}
      # saveable attributes
      ([:hide, :scope, :marked?, :toogle_mark!, :details, :views, :sorts, :pages, :search, :has_markings?] << PRESERVING_PARAMS).each do |saved_attribute|
        @saved_options[saved_attribute] = options[saved_attribute] if options.include?(saved_attribute)
      end
      
      @save = options.delete(:save)
      @eval_options = options.include?(:eval_options) ? options.delete(:eval_options) : []
      @hide = options.delete(:hide) #array
      @scope = options.delete(:scope) #scope
      @search = options.delete(:search) #scope
      @has_markings = options.delete(:has_markings?) #boolean
      @marked = options.delete(:marked?) #method name of the note model
      @toogle_mark = options.delete(:toogle_mark!) #method name of the note model
      @per_page = options.delete(:per_page) #int
      @details = options.delete(:details) #lambda
      @form = options.delete(:form) #lambda
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
    def details; @details; end
    def form; @form; end
    def eval_options; @eval_options; end
    def has_markings?; @has_markings; end
    
    def filters
      f = []
      f << @views[@view.to_i].last unless @views.blank? && @view.blank?
      f << @sorts[@sort.to_i].last unless @sorts.blank? && @sort.blank?
      (f - [nil]).flatten
    end
        
    def all_notes(more=nil)
      scopes = []
      scopes << @scope.to_sym unless @scope.blank?
      scopes << filters
      if more.nil?
        scopes << @search unless search_text.blank?
      else
        scopes << more unless more.nil?
      end
      scopes.flatten!
      scopes -= [nil]
      
      allnotes = ["note_class"]
      scopes.each do |scope|
        allnotes << "send(:#{scope}, self)"
      end
      RAILS_DEFAULT_LOGGER.debug("all_notes: #{allnotes.join('.')}")
      debugger
      eval allnotes.join('.')
    end
    
    def marked?(note)
      debugger
      note.send(@marked.to_sym)
    end
    
    def toogle_mark!(note)
      note.send(@toogle_mark.to_sym)
    end
    
    def saveable?
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