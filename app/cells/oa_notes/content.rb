module OANotes
  class Content < OAWidget::Base    
    
    responds_to_event :paginate,  :with => :update_content
    responds_to_event :delete,    :with => :delete
    responds_to_event :mark,      :with => :mark
    
    module ::ContentHelper
      def parent; @cell.parent; end
      def deletable?(note); parent.delete?(note); end
      def editable?(note); parent.update?(note); end
      def has_markings?; parent.has_markings?; end
      def marked?(note); parent.marked?(note); end
      def markable?(note); parent.toogle_mark?(note); end
    end
    
    helper ::ContentHelper
    
    def initialize(widget_id, options={})
      preserves_attrs(options.delete(:preserve))
      super(widget_id, :content, options)
    end

    def content
      load_notes
      render
    end
    
    def update_content
      load_notes
      replace :view => 'content'
    end
        
    def delete
      @note = find_note(param(:id))
      @note.destroy
      self.invoke(:update_content)
    end
    
    def mark
      @note = find_note(param(:id))
      parent.toogle_mark!(@note)
      self.invoke(:update_content)
    end
    
    private 
    def load_notes
      @notes = parent.all_notes.paginate(:per_page => @per_page, :page => (param(:page) || 1).to_i)
    end
    
    def find_note(id)
      parent.eval_note.find(id)
    end
    
  end
end