; +
; $Id: lc_match_struct__define.pro,v 1.3 2015/03/03 20:09:45 jpmorgen Exp $

; lc_match_struct__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; This structure allows a list of arbitrary length to be constructed
;; containing catalog array indices.  It is intended to be used with
;; lc_match and lc_build and to help merge multiple line catalogs.
;; locate 

;; Tag		Meaning
;; cat		Catalog number for this match.  See lc_sysvar__define
;; 		for catalog/number correspondences 
;; idx		Index of the wavelength record in the matching catalog 
;; next		Pointer to the next element in the linked list.
;;

pro lc_match_struct__define
  lc_match_struct $
    = {lc_match_struct, $
       cat		: 0,  $
       idx		: long(0), $
       diff		: 0D}

end


