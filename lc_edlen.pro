; +
;; $Id: lc_edlen.pro,v 1.1 2015/03/03 20:09:16 jpmorgen Exp $

;; lc_edlen
;;
;; Convert from vacuum wavenumber (aka sigma or s) in 1/cm to air
;; wavelength in Angstroms using Edlen's formula.  If s in an array,
;; it is returned in reverse order unless /noreverse is specified.


; -

function lc_edlen, s, noerror=noerror, noreverse=noreverse

  ;; Edlen's formula gives the index of refraction of air for
  ;; wavelengths > 2000 A.  Make sure that 

  bad_idx = where(1E8/s lt 2000, count)
  if count gt 0 and NOT keyword_set(noerror) then $
    message, 'ERROR: Edlen''s formula is not valid for wavelengths < 2000 A (>50000 1/cm).  Use /noerror to force conversion.'

  n = 1 + 6432.8d-8 + 2949810d/(146d8-s^2) + 25540d/(41d8-s^2)

  if keyword_set(noreverse) then $
    return, 1d8 / (n * s)

  return, reverse(1d8 / (n * s))

end
