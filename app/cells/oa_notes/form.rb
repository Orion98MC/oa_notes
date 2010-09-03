module OANotes
  class Form < OAWidget::Base
    
    responds_to_event :create, :with => :create_note
    responds_to_event :update, :with => :update_note
    responds_to_event :cancel, :with => :update_form
    responds_to_event :add_note, :with => :show_form
    
    module ::FormHelper
      def parent; @cell.parent; end
      
      def note_form(note, &block)
        unless @form.blank?
          if @eval_options.include?(:form)
            logger.debug("capture eval note")
            concat capture{eval(@note_content).call(note)}
          else
            logger.debug("capture note")
            concat capture{@note_content.call(note)}
          end
        else
          logger.debug("capture yield note")
          if block_given?
            concat capture(&block)
          end
        end
      end
    end
    
    helper ::FormHelper
    
    def initialize(widget_id, options={})
      preserves_attrs(options.delete(:preserve))
      @form = options.delete(:form)
      @eval_options = options.include?(:eval_options) ? options.delete(:eval_options) : []
      super(widget_id, :form, options)
    end
    
    def form # The form to add notes      
      @note = parent.note_class.new()
      if parent.hidden?(:form)
        render parent.creatable? ? {:view => 'hidden'} : {:nothing => true}
      else
        render :view => 'shown'
      end
    end
    
    def show_form
      @note = parent.note_class.new()
      replace :view => 'shown'
    end
    
    def update_form
      @note = parent.note_class.new()
      if parent.hidden?(:form)
        replace parent.creatable? ? {:view => 'hidden'} : {:nothing => true}
      else
        replace :view => 'shown'
      end      
    end
          
    #pragma mark -
    #pragma mark The triggered actions
    
    def create_note
      @note = parent.note_class.new(param(:note))

      if @note.save
        trigger :content_changed
        invoke :update_form
      else
        replace :view => 'shown'
      end
    end
    
    def update_note
      begin
        @note = parent.note_class.find(param(:id))
      rescue
        trigger :content_changed
        return invoke :update_form
      end
      
      if @note.update_attributes(param(:note))
        trigger :content_changed
        invoke :update_form
      else
        replace :view => 'shown'
      end
    end
    
    def edit
      @note = parent.note_class.find(param(:id))
      replace :view => 'shown'
    end
        
  end
end