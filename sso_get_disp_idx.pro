;+
; NAME: sso_get_disp_idx
;
;
;
; PURPOSE: returns the index of the linear dispersion coefficient from
; a list of sso_parinfo structures.
;
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS: index of the linear dispersion coefficient
;
;
;
; OPTIONAL OUTPUTS: indices of the whole dispersion relation
;
;
;
; COMMON BLOCKS:  
;
;   Common blocks are ugly.  Consider using package-specific system
;   variables.
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
; $Id: sso_get_disp_idx.pro,v 1.1 2015/03/03 20:13:16 jpmorgen Exp $
;-
function sso_get_disp_idx, parinfo, idx=idx, ndisp=ndisp


  if NOT keyword_set(idx) then $
    idx = lindgen(N_elements(parinfo))

  disp_idx = where(parinfo[idx].pfo.inaxis eq !pfo.Xin and $
                   parinfo[idx].pfo.outaxis eq !pfo.Xaxis, ndisp)
  if ndisp eq 0 then $
    return, -1

  ;; unwrap
  disp_idx = idx[disp_idx]

  ftypes = parinfo[disp_idx].pfo.ftype - !pfo.poly
  prnums = round(ftypes * 100. )
  pridx = where(0 lt prnums and prnums lt 10, count)
  if count ne 1 then $ $
    message, 'ERROR: ' + strtrim(count, 2) + ' reference pixels found.  I can only handle 1'
  ;; get dispersion polynomial
  cftypes =  ftypes * 1000.
  rcftypes = round(cftypes)
  c0idx = where(0 lt rcftypes and rcftypes lt 10 and $
                round(cftypes * 10.) eq rcftypes * 10, $
                npoly)
  if npoly ne 1 then $
    message, 'ERROR: '  + strtrim(npoly, 2) + ' dispersion polynomials found.  I can can only handle 1'
  ldisp_idx = where(round(ftypes * 10000.) - 10 eq 1, count)
  if count ne 1 then $
    message, 'ERROR: improper number of first-order polynomial coefficients found (' + strtrim(count, 2) + ')'


  return, ldisp_idx

end
