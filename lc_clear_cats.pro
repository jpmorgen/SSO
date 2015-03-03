; +
;; $Id: lc_clear_cats.pro,v 1.1 2015/03/03 20:08:33 jpmorgen Exp $

;; lc_clear_cats

;; Clear the !lc.cats heap variable

; -

pro lc_clear_cats

  while(ptr_valid(!lc.cats)) do begin
     ;; pop things off the front of the list
     t = !lc.cats
     !lc.cats = (*t).next
     ptr_free, t
  endwhile

end
