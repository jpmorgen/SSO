; +
; $Id: sso_dg_struct__define.pro,v 1.2 2015/03/03 20:17:27 jpmorgen Exp $

; sso_dg_struct__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; This structure allows a list of arbitrary length to be constructed
;; containing lc/sso path designations and their corresponding Doppler
;; group assignments.

;; Tag		Meaning
;; dg		Doppler group number (dynamically assigned)
;; path		see lc_struct__define documentation
;; names	JPL ephemerides names
;; next		Pointer to the next element in the linked list.
;;

pro sso_dg_struct__define, dg_struct=dg_struct
  dg_struct $
    = {dg_struct, $
       dg	: 0, $
       path	: lonarr(10), $
       names	: strarr(10), $
       dv	: double(0), $
       next	: ptr_new()}
  ;; Initialize
  dg_struct.path[*] = -1
  dg_struct.dv = !values.d_nan
  
end


