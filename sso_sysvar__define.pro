; +
; $Id: sso_sysvar__define.pro,v 1.2 2004/01/15 17:07:23 jpmorgen Exp $

; sso_sysvar__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  So call explicitly with an
; argument if you need to have a default structure with different
; initial values, or as in the case here, store the value in a system
; variable.

;; This defines the !sso system variable, which contains some handy
;; tokens for refering to objects, Doppler groups, etc.  The idea is
;; to have code read in english, so unique token IDs are not
;; necessary.  If the numbering scheme changes, just change the token
;; values and everything still works.  Stick an initialized
;; pfo_parinfo record on the end for handy reference.
; -

pro sso_sysvar__define
  ;; System variables cannot be redefined and named structures cannot
  ;; be changed once they are defined, so it is OK to check this right
  ;; off the bat
  defsysv, '!sso', exists=sso_exists
  if sso_exists eq 1 then return
  
  ;; Read in and customize the pfo system variable.  Make sure this is
  ;; after the bailout point, or else the customizations won't stick.
  init = {pfo_sysvar}
  !pfo.pname_width = 15
  !pfo.longnames = 0
  
  sso_dg_struct__define, dg_struct=dg_struct
  sso_parinfo__define, parinfo=sso_parinfo
  sso $
    = {sso_sysvar, $
       null	:	0, $	;; IMPORTANT THAT NULL BE 0
       $ ;; The value of c defines velocity units.  dwcvt (delta 
       $ ;; wavelength convert) converts delta wavelength into
       $ ;; wavelength units.  ewcvt, when multiplied by the 
       $ ;; continuum, converts equivalent width to area.  Be 
       $ ;; default, delta wavelength and equivalent width read
       $ ;; in milli Angstroms
       c	: 299792.458d, $ ;; km/s, double precision
       dwcvt	: 0.001d, $
       ewcvt	: 0.001d, $
       lwcvt	: 0.001d, $
       $ ;; ptype (parameter type) tokens.  The whole ptype tag is 
       $ ;; somewhat redundant, since pfo.ID could be used and the 
       $ ;; purpose of the parameter could probably be constructed 
       $ ;; from the other pfo.* keywords.  However, the idea is to
       $ ;; provide enough tags to make things really easy to deal 
       $ ;; with, not to save little bits of memory here and there.
       dop	:	1,   $  ;; Doppler shift
       cont	:	2,   $  ;; continuum parameter
       line	:	3,   $  ;; line parameter
       $ ;; ptype names.  --> These might be a bit long
       ptnames	:	['nonsso', 'Dop', 'cont', 'line'], $
       $ ;;  SSO transformation tokens
       center	:	1, $
       area	:	2, $
       width	:	3, $
       $ ;; Doppler group correspondences are stored as a linked list
       dgs	:	ptr_new(),    $
       aterm	:	-1., $	;; Array terminator for dg path array
       rwl_format:	'(f9.4)', $ ;; format for rest wavelength printing
       $ ;; Tack on an initialized dg_struct and sso_parinfo record
       dg_struct:	dg_struct, $
       parinfo	:	sso_parinfo}

  defsysv, '!sso', sso

end
