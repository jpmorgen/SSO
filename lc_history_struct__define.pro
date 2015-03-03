; +
; $Id: lc_history_struct__define.pro,v 1.1 2015/03/03 20:10:26 jpmorgen Exp $

; lc_history_struct__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; This structure allows a list of arbitrary length to be constructed
;; containing catalog array indices.  It is intended to be used with
;; lc_history and lc_build and to help merge multiple line catalogs.
;; locate 

;; Tag		Meaning
;; cat		Catalog number for this history.  See lc_sysvar__define
;; 		for catalog/number correspondences 
;; idx		Index of the wavelength record in the historying catalog 
;; next		Pointer to the next element in the linked list.
;;

pro lc_history_struct__define
  lc_history_struct $
    = {lc_history_struct, $
       cat		: 0,  $
       src		: 0,  $
       wavelen		: 0D, $
       serial		: 0,  $
       version		: 0,  $
       ptype		: 0,  $
       change		: 0D}

  
end


