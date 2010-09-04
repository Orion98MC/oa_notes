module OANotes
  class Form < OAWidget::Base
    
    responds_to_event :create, :with => :create_note
    responds_to_event :update, :with => :update_note
    responds_to_event :cancel, :with => :update_form
    responds_to_event :add_note, :with => :show_form
    
    module ::FormHelper
      def parent; @cell.parent; end
    end
    
    helper ::FormHelper
    
    def initialize(widget_id, options={})
      preserves_attrs(options.delete(:preserve))
      super(widget_id, :form, options)
    end
    
    def form # The form to add notes      
      @note = new_note()
      if parent.hidden?(:form)
        render parent.create? ? {:view => 'hidden'} : {:nothing => true}
      else
        render :view => 'shown'
      end
    end
    
    def show_form
      @note = new_note()
      replace :view => 'shown'
    end
    
    def update_form
      @note = new_note()
      if parent.hidden?(:form)
        replace parent.create? ? {:view => 'hidden'} : {:nothing => true}
      else
        replace :view => 'shown'
      end      
    end
          
    #pragma mark -
    #pragma mark The triggered actions
    
    def create_note
      @note = new_note(param(:note))

      if @note.save
        trigger :content_changed
        invoke :update_form
      else
        replace :view => 'shown'
      end
    end
    
    def update_note
      begin
        @note = find_note(param(:id))
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
      @note = find_note(param(:id))
      replace :view => 'shown'
    end
    
    private
    def new_note(options={})
      parent.eval_note.new(options)
    end
    
    def find_note(id)
      parent.eval_note.find(id)
    end
        
  end
end