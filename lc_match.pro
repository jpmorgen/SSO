; +
;; $Id: lc_match.pro,v 1.1 2015/03/03 20:09:30 jpmorgen Exp $

;; lc_match
;;
;; Recursively crawl through a catalog array (ca) to find matching
;; lines.  Uses an lc match struct to store match information.  Since
;; ca is an array of pointers, we don't really need to pass idx, but
;; do so just to appear like we are making sure we are passing arrays
;; by reference instead of by copying.

; -

pro lc_match, ca, idx

  if NOT keyword_set(idx) then $
    idx = lindgen(N_elements(ca))
  nc = N_elements(idx)
  if nc lt 2 then return

  ;; Generate matches between the first catalog and all the rest
  c1 = ca[0]
  for i=1,N_elements(idx)-1 do begin
     c2 = ca[i]
     lc_match_two, c1, c2
     ca[i] = c2
  endfor

  ;; Start recursion process to generate matches between the rest of
  ;; the catalogs
  lc_match, ca, idx[1:nc-1]     

end
