; +
; $Id: sso_voigt.pro,v 1.1 2004/01/14 17:43:52 jpmorgen Exp $

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

  if keyword_set(center) then begin
     idx = where(0.09 lt dftypes and dftypes lt 0.11)
     case center of
        !sso.on : parinfo[idx[idx]].sso.ttype = !sso.center
        !sso.off: parinfo[idx[idx]].sso.ttype = !sso.null
        else	: message, 'ERROR: unrecognized transformation directive: center = ' + string(center)
     endcase
  endif     
  if keyword_set(area) then begin
     idx = where(0.19 lt dftypes and dftypes lt 0.21)
     case area of
        !sso.on : parinfo[idx[idx]].sso.ttype = !sso.area
        !sso.off: parinfo[idx[idx]].sso.ttype = !sso.null
        else	: message, 'ERROR: unrecognized transformation directive: area = ' + string(area)
     endcase
  endif     
  if keyword_set(width) then begin
     idx = where(dftypes gt 0.2)
     case width of
        !sso.on : parinfo[idx[idx]].sso.ttype = !sso.width
        !sso.off: parinfo[idx[idx]].sso.ttype = !sso.null
        else	: message, 'ERROR: unrecognized transformation directive: width = ' + string(width)
     endcase
  endif     

end

