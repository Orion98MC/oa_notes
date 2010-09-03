module OANotes
  class Filters < OAWidget::Base

    def initialize(widget_id, options={})
      preserves_attrs(options.delete(:preserve))
      super(widget_id, :filters, options)
    end
    
    def filters
      render
    end
        
  end
end