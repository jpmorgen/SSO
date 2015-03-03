; +
; $Id: sso_voigt.pro,v 1.2 2015/03/03 20:16:04 jpmorgen Exp $

; sso_voigt.pro 

;; Each pfo primitive used as an sso primitive needs a routine to
;; indicate which parameters normally undergo an sso transformation.

; -

;; Handle _EXTRA, since it may be defined in sso_fmod because of sso
;; or mpfit tags.

pro sso_voigt, parinfo, idx, center=center, area=area, width=width, $
               _EXTRA=extra

  init = {sso_sysvar}

  dftypes = parinfo[idx].sso.pfo.pfo.ftype - $
            fix(parinfo[idx].sso.pfo.pfo.ftype)

  if N_elements(center) ne 0 then begin
     tidx = where(0.09 lt dftypes and dftypes lt 0.11)
     parinfo[idx[tidx]].sso.ttype = !sso.center
  endif     
  if N_elements(area) ne 0 then begin
     tidx = where(0.19 lt dftypes and dftypes lt 0.21)
     parinfo[idx[tidx]].sso.ttype = !sso.area
  endif     
  if N_elements(width) ne 0 then begin
     tidx = where(dftypes gt 0.2)
     parinfo[idx[tidx]].sso.ttype = !sso.width
  endif     

end

