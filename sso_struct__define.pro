; +
; $Id: sso_struct__define.pro,v 1.1 2004/01/14 17:40:14 jpmorgen Exp $

; sso_parinfo__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; SSO specific tags to be added to the parinfo structure.

;; Tag		Meaning
;; ptype	parameter type
;;		1 = parameter used to define the continuum
;;		2 = parameter is a Doppler shift
;;		3 = parameter is used to define a line
;; ttype	Transformation type.  See sso documentation for
;; 		details about transformations
;;		1 = line center transformation
;;		2 = equivalent width transformation
;;		3 = linewidth transformation
;; dg		Doppler group.  Dynamically assigned at run time.  All
;; 		parameters associated with a particular line,
;; 		continuum, or the Doppler shift itself must have a
;; 		properly assigned dg value.  dg = 0 is the rest frame
;; rwl		Rest wavelegth
;; owl		Observed wavelength (after calculation of Doppler shift)
;; path		See lc_struct__define.pro documentation.
;; pfo		A pfo_parinfo structure that contains the pfo.ftype,
;; 		etc. fields necessary to calculate 


pro sso_struct__define, sso_struct=sso_struct
  ;; Put the whole pfo_parinfo structure under the sso_struct, since I
  ;; think that might speed up memory operations in pfo_sso_funct
  pfo_parinfo__define, parinfo=pfo
  ;;pfo = {pfo : {pfo_struct}}
  sso_struct $
    = {sso_struct, $
       ptype		: 0, $
       ttype		: 0, $
       dg		: 0, $
       rwl		: 0D,$
       owl		: 0D,$
       path		: lonarr(10), $
       pfo		: pfo}
  sso_struct.rwl = !values.d_nan
  sso_struct.owl = !values.d_nan
  sso_struct.path[*] = -1
  
end
