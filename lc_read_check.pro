; +
;; $Id: lc_read_check.pro,v 1.1 2003/12/18 23:59:18 jpmorgen Exp $

;; lc_read_check
;;


; -

function lc_read_check, cat_id

  list = !lc.cats
  while(ptr_valid(list)) do begin
     if (*list).cat[0].cat eq cat_id then $
       return, list
     list = (*list).next
  endwhile
  ;; If we get here, we failed to find the catalog in !lc.cats
  return, ptr_new()

end
