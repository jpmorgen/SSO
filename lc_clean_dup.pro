; +
;; $Id: lc_clean_dup.pro,v 1.1 2003/12/18 23:59:53 jpmorgen Exp $

;; lc_clean_dup 
;;
;; Remove entries marked by lc_sort as duplicate wavelength, src, and
;; ptype.  Flag for removal is a negative catalog number.  You can
;; pass the sorted index values returned by lc_sort, so the array gets
;; put into proper order when it is copied.

; -

function lc_clean_dup, lc, sidx

  if N_elements(sidx) lt N_elements(lc) then $
    sidx = indgen(N_elements(sidx))

  good_idx = where(lc[sidx].cat ge 0, count)
  if count lt 0 then $
    message, 'ERROR: no good entries in catalog'

  return, lc[sidx[good_idx]]

end
