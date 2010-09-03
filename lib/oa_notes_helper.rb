module OANotesHelper
  
  def oa_notes_javascripts
    ['jScrollPane'].collect{|js| 'oa_notes/' + js}
  end
  
  def oa_notes_stylesheets
    ['jscroller', 'oa_notes-scroller', 'oa_notes'].collect{|style| 'oa_notes/' + style}
  end
end