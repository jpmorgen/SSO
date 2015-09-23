; +

; sso_ana_struct__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this procedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; Tags to help analyze the stability of line parameters and establish
;; MPFIT limits of a set of SSO fits.  This helps make plots of
;; parinfo.value vs. delta wavelength from the closest N lines.

;; For each element in a parinfo, we append the structure below, which
;; keeps track of the corresponding parameter values of the closest N
;; lines.  Non-line parameters have these values set to NAN.  The
;; system stores the most information if all the lines in a given
;; parinfo are described by the same number of parameters (e.g. they
;; are all Voigts), but since we mostly care about the delta in the
;; observed wavelengths and its effect on the top-level parameter
;; value (parinfo.value) and we can always look up the close line with
;; its rest wavelength (RWL), it is OK if things don't all quite fit.

pro sso_ana_struct__define, sso_ana_struct=sso_ana_struct
  ;; We may want to track the effect of the N closest lines on this
  ;; particular parameter of our host line.  The primary plot we are
  ;; looking for in our *ana_close_lines routines is host line
  ;; parameter vs. delta wavelength (DOWL) from the closest line, so
  ;; we need a DOWL for each close line.  While we are at it, make
  ;; room for the value, error, etc. of the close line parameter.
  ;; These might be used for weighting the effect of close lines down
  ;; the road.  We also want to store some global characteristics for
  ;; each fit, so they are easy for *ana_close_lines to follow
  N_close_lines = 3
  sso_ana_struct $
     = {sso_ana_struct, $
        redchisq	: 0D, $			   ;; Reduced chi2 of host line spectral fit
        delta_dop	: 0D, $			   ;; Delta Doppler shift from expected Doppler shift of host line
        err_delta_dop	: 0D, $			   ;; error in Delta Doppler shift from expected Doppler shift of host line
        RWL             : dblarr(N_close_lines), $ ;; Rest wavelengths of close lines
        dg              : intarr(N_close_lines), $ ;; Doppler groups of close lines
        DOWL            : dblarr(N_close_lines), $ ;; Difference between observed wavelegnths of close line and the "host" line of this structure
        err_DOWL        : dblarr(N_close_lines), $ ;; Error in difference between observed wavelegnths of close line and the "host" line of this structure
        path            : lonarr(N_close_lines, 10), $ ;; Paths of close lines
        value           : dblarr(N_close_lines), $ ;; parameter values of close lines
        error           : dblarr(N_close_lines)}   ;; error in parameter values of close lines
  
  ;; When the structure is defined, it nulls out the originally
  ;; assigned values, so I need to put them back
  sso_ana_struct.RWL     = !values.d_NAN        
  sso_ana_struct.value   = !values.d_NAN        
  sso_ana_struct.error   = !values.d_NAN        
  
end
