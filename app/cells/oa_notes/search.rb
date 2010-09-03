module OANotes
  class Search < OAWidget::Base
            
    def initialize(widget_id, options={})
      preserves_attrs(options.delete(:preserve))
      super(widget_id, :search, options)
    end
    
    def search
      render
    end
            
  end
end