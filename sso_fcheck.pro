; +
; $Id: sso_fcheck.pro,v 1.1 2004/01/14 17:40:51 jpmorgen Exp $

; sso_fcheck.pro 

;; Check the validity of any sso functions defined in parinfo, fixing
;; up trivial problems.

;; WARNING: only sso_fcreate and pfo_sso_funct should call this
;; routine directly.  In all other cases, use 
;;
;; junk=pfo_funct([0], parinfo=parinfo, /sso_check)
;;
;; whenever possible to make sure multiple SSO functions are parsed
;; properly.

;; WARNING: an entire parinfo array must be passed in order for the
;; values to be permanently changed (see IDL manual "passing by
;; reference" section).  Use the idx positional parameter to pick out
;; individual parinfo records.

; -

pro sso_fcheck, parinfo, idx

  ;; Errors will make more sense in the calling function
;;  ON_ERROR, 2

  init = {sso_sysvar}

  ;; Pathological case, avoids indgen(0) error
  n = N_elements(parinfo)
  if N_elements(parinfo) eq 0 then $
    return

  ;; Set up idx if none specified
  if N_elements(idx) eq 0 then $
    idx = indgen(n)

  sso_idx = where(parinfo[idx].pfo.ftype eq !pfo.sso, count)
  ;; Return quietly if we have no sso functions
  if count eq 0 then return

  ;; Unwrap indices
  sso_idx = idx[sso_idx]
  
  ;; This part will work even if we have multiple sso functions.  

  sso_dg_assign, parinfo, idx

  ;; --> Assume for now that we have just one sso function.  There may
  ;; be a way to recursively check this.  Don't want to think about it
  ;; now.  Hope warning message above is enough.

  ;; If the user has given us a path and rest wavelength, then they
  ;; assume they want the Doppler shift calculated.  Find the
  ;; functions that match this criterion
  fc_idx = where(parinfo[sso_idx].sso.dg ne !sso.null and $
                 finite(parinfo[sso_idx].sso.rwl), nc)
  ;; And mark their centers
  if nc gt 0 then $
     sso_fmod, parinfo, sso_idx[fc_idx], /center
  
end

