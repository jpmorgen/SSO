; +
;; $Id: lc_build.pro,v 1.1 2015/03/03 20:10:35 jpmorgen Exp $

;; lc_build
;;
;; Using an array of catalogs that have already been matched with
;; lc_match, build up the best catalog 

; -

function lc_build, ca

  for ic=0,N_elements(ca)-1 do begin
     for il = 0, N_elements(*ca[ic])-1 do begin
        if ptv_valid((*ca[ic])[il].pml) then begin
        endif else begin
           element = (*ca[ic])[il]
        endelse
        nc = array_append(element, nc)
     endfor
  endfor
  return, nc
end
