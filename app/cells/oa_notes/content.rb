module OANotes
  class Content < OAWidget::Base    
    
    responds_to_event :paginate,  :with => :update_content
    responds_to_event :delete,    :with => :delete
    responds_to_event :mark,      :with => :mark
    
    module ::ContentHelper
      def parent; @cell.parent; end
      def deletable?(note); parent.deletable?(note); end
      def editable?(note); parent.editable?(note); end
      def has_markings?; parent.has_markings?; end
      def marked?(note); parent.marked?(note); end
      def markable?(note); parent.markable?(note); end
      
      def note_content(note, &block)
        unless @note_content.blank?
          if @eval_options.include?(:note_content)
            logger.debug("capture eval note")
            capture{eval(@note_content).call(note)}
          else
            logger.debug("capture note")
            capture{@note_content.call(note)}
          end
        else
          logger.debug("capture yield note")
          if block_given?
            capture(&block)
          end
        end
      end
    end
    
    helper ::ContentHelper
    
    def initialize(widget_id, options={})
      preserves_attrs(options.delete(:preserve))
      @note_content = options.delete(:note_content)
      @eval_options = options.include?(:eval_options) ? options.delete(:eval_options) : []
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
      @note = parent.note_class.find(param(:id))
      @note.destroy
      self.invoke(:update_content)
    end
    
    def mark
      @note = parent.note_class.find(param(:id))
      parent.toogle_mark!(@note)
      self.invoke(:update_content)
    end
    
    private 
    def load_notes
      @notes = parent.all_notes.paginate(:per_page => @per_page, :page => (param(:page) || 1).to_i)
    end
    
  end
end