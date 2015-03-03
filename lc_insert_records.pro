; +
;; $Id: lc_insert_records.pro,v 1.1 2015/03/03 20:10:07 jpmorgen Exp $

;; lc_insert_records 

;; Insert lcr (line catalog record) into lca (line catalog array) so
;; lca ends up with a monotonically increasing wavelength sequence.
;; lcr can be an array (e.g. the wavelength and equivalent width
;; values for a line), but must have the same .wavelen tag.
;;
; -
pro lc_insert_records, lcr, lca
  if N_elements(lcr) gt 1 then begin
     check = uniq(lcr.wavelen)
     if N_elements(check) ne 1 then $
       message, 'ERROR: all the lcr elements must refer to the same line'
  endif

  nr = N_elements(lca)

  ;; Start of list with lca undefined
  if nr eq 0 then begin
     lca = lcr
     return
  endif

  ;; Start of list with lca set to a different type from lcr
  if N_elements(lca) eq 1 and $
    size(lca, /type) eq size(lcr, /type) then begin
     lca = lcr
     return
  endif

  ;; Assume lcr belongs at the head of the list, even though it
  ;; usually doesn't.
  idx = 0

  ;; This should be the usual case when we are building from an
  ;; already ordererd catalog.  Be efficient with code an flag for
  ;; using array_insert
  if lca[nr-1].wavelen le lcr[0].wavelen then begin
     idx = nr
     nr = 0
  endif

  while nr gt 1 do begin
     ;; If we get here, lcr belongs somewhere inside of lca
     nr = nr - 1
     if lca[nr-1].wavelen le lcr[0].wavelen and $
        lcr[0].wavelen lt lca[nr].wavelen then begin
        idx = nr
        nr = 0
     endif
  endwhile
  array_insert, lcr, lca, idx

end

