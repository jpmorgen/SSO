; +
; $Id: sso_sysvar__define.pro,v 1.3 2013/01/03 23:38:52 jpmorgen Exp $

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

  init = {lc_sysvar}
  
  sso_dg_struct__define, dg_struct=dg_struct
  sso_parinfo__define, parinfo=sso_parinfo
  sso $
    = {sso_sysvar, $
       null	:	0, $	;; IMPORTANT THAT NULL BE 0
       $ ;; Wavelengths of strong airglow lines (> 100
       $ ;; 10^-16 erg/(s A cm^2 arcsec^2)) as measured by 
       $ ;; http://www.eso.org/observing/dfo/quality/UVES/pipeline/sky_spectrum.html
       $ ;; I am having a hard time finding the best wavelength
       $ ;; for the green airglow line.  --> There are quite a few
       $ ;; lines with fluxes > 10, particularly in the IR
       airglow_lines: [5577.34d, 6300.304d], $
       $ ;; The value of c defines velocity units.  dwcvt (delta 
       $ ;; wavelength convert) converts delta wavelength into
       $ ;; wavelength units.  ewcvt, when multiplied by the 
       $ ;; continuum, converts equivalent width to area.  Be 
       $ ;; default, delta wavelength and equivalent width read
       $ ;; in milli Angstroms
       c	: !lc.c/1000d, $ ;; km/s, double precision
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
       ew	:	2, $
       width	:	3, $
       $ ;; Doppler group correspondences are stored as a linked list
       $ ;; type dg_struct.  Other packages (e.g. ssg) need their own 
       $ ;; dg_struct, and structures cannot be redefined, so make a 
       $ ;; pointer/heap variable that can be dynamically reassigned
       $ ;; (see below).
       dgs	:	ptr_new(), $
       dg_struct_ptr:	ptr_new(), $
       $ ;; Special lines, (e.g. Na and [OI] for Io) that are singled 
       $ ;; out in sso_plot_fit.  Make a separate parinfo array of 
       $ ;; these lines and assign this pointer to that array.
       special_lines:	ptr_new(), $
       $ ;; minimum number pf lines needed before a Doppler shifted
       $ ;; axis for a particular Doppler group is plotted.
       min_lines:	1, $
       aterm	:	-1., $	;; Array terminator for dg path array
       rwl_format:	'(f9.4)', $ ;; format for rest wavelength printing
       $ ;; Tack on an initialized dg_struct and sso_parinfo record
       dg_struct:	dg_struct, $
       parinfo	:	sso_parinfo}

  defsysv, '!sso', sso
  ;; Just in case something other than sso_dg_assign wants to creatre
  ;; new dg_struct records for dgs, initialize this here.
  !sso.dg_struct_ptr = ptr_new(!sso.dg_struct, /no_copy)

end
