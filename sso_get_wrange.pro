;+
; NAME: sso_get_wrange
;
;
;
; PURPOSE: 
;
; Returns the wavelength range that includes at least min_lines lines
; from each Doppler group of the active parameters in parinfo.  If
; this is a subset of the input wavelength range is larger, the input
; wavelength range is returned unchanged.
;
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE: 
; 	wrange = sso_get_wrange(pix_axis, parinfo, min_lines,
; 	iwrange, idx=idx, omit=omit)
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
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
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
; $Id: sso_get_wrange.pro,v 1.1 2015/03/03 20:13:12 jpmorgen Exp $
;-

function sso_get_wrange, pix_axis, parinfo, min_lines, iwrange, idx=idx, $
  omit=omit

  if N_elements(pix_axis) eq 0 then $
    message, 'ERROR: pix_axis must be specified'
  if N_elements(parinfo) eq 0 then $
    message, 'ERROR: no parinfo supplied'
  if N_elements(omit) eq 0 then $
    omit = -1 ;; a resonable null Doppler tgroup
  if NOT keyword_set(idx) then $
    idx = lindgen(N_elements(parinfo))
  fidx = where(parinfo[idx].pfo.status eq !pfo.active, count)
  if count eq 0 then $
    message, 'ERROR: no active parameters'
  ;; unwrap
  fidx = idx[fidx]
  ;; Do Doppler group and model calculation stuff to make sure OWLs
  ;; are correct
  sso_dg_assign, parinfo, idx, count=ndop
  if ndop eq 0 then $
    message, 'ERROR: parinfo has no Doppler groups.  There should be at least one (e.g. earth-earth)'
  dop_idx = where(parinfo[fidx].sso.ptype eq !sso.dop)
  ;; unwrap
  dop_idx = fidx[dop_idx]
  ;; This should raise an error if there are any severe problems
  model_spec = pfo_funct(pix_axis, parinfo=parinfo, xaxis=xaxis, idx=fidx)

  if N_elements(min_lines) eq 0 then $
    min_lines = 3
  if N_elements(iwrange) eq 0 then $
    iwrange = mean(xaxis)
  if N_elements(iwrange) eq 1 then $
    iwrange = [iwrange, iwrange]
  owcenter = mean(iwrange)

  ;; Fine the ative line center indices
  lc_idx = where(parinfo[fidx].pfo.status eq !pfo.active and $
                 parinfo[fidx].sso.ttype eq !sso.center and $
                 parinfo[fidx].sso.ptype eq !sso.line, nlines)
  if nlines eq 0 then $
    message, 'ERROR: no lines found'
  ;; unwrap
  lc_idx = fidx[lc_idx]
  ;; Make an array that has the number of lines per dg and their
  ;; indices
  dg_lcidx = make_array(ndop, nlines+1, /long, value=-1)
  for idg=0,ndop-1 do begin
     dg = parinfo[dop_idx[idg]].sso.dg
     tidx = where(parinfo[lc_idx].sso.dg eq dg, nidx)
     dg_lcidx[idg,0] = nidx
     ;; Print warning message for too few lines if we are not an
     ;; omitted Doppler group
     junk = where(omit eq dg, nomit)
     if nidx lt min_lines and nomit eq 0 then begin
        message, /CONTINUE, 'WARNING: not enough lines in Doppler group ' + strjoin(sso_dg_path(dg, /name), '-') + ' ( ' + strtrim(nidx, 2) + ' to meet minimum line request of ' + strtrim(min_lines, 2)
     endif
     if nidx eq 0 then $
       CONTINUE
     ;; unwrap
     tidx = lc_idx[tidx]
     dg_lcidx[idg,1:nidx] = tidx
  endfor ;; each Doppler group: constructing dg_lcidx

  good_idx = where(dg_lcidx[*,0] ge min_lines, ndg)
  if ndg eq 0 then begin
     message, /CONTINUE, 'WARNING: No Doppler groups have enough lines to meet minimum line request of ' + strtrim(min_lines, 2) + ' returning input wavelength range'
     return, iwrange
  endif

  ;; Find the wrange centered on iwrange that encompasses min_lines
  ;; for each Doppler group that has enough lines
  wrange = iwrange
  for idg=0,ndg-1 do begin
     gidx = good_idx[idg]
     nidx = dg_lcidx[gidx,0]
     tlc_idx = dg_lcidx[gidx,1:nidx]
     owls = parinfo[tlc_idx].sso.owl
     dg = parinfo[tlc_idx[0]].sso.dg
     inidx = where(wrange[0] le owls and owls le wrange[1], nin)
     if nin eq 0 then begin
        ;; find owls on either side of wrange
        lidx = where(owls le wrange[0], nleft)
        if nleft eq 0 then begin
           message, /CONTINUE, 'WARNING: left side of input wavelength range was lower than smallest wavelength line in Doppler group ' + strjoin(sso_dg_path(dg, /name), '-')
           lidx = 0
        endif
        ridx = where(owls ge wrange[1], nright)
        if nright eq 0 then begin
           message, /CONTINUE, 'WARNING: right side of input wavelength range was higher than largest wavelength line in Doppler group ' + strjoin(sso_dg_path(dg, /name), '-')
           ridx = N_elements(owls) - 1
        endif
        inidx = [max([lidx]), min([ridx])]
        nin = 2
        wrange = [owls[min(inidx)], owls[max(inidx)]]
     endif ;; [i]wrange wasn't large enough to include any lines from this dg

     ;; --> There might be an infinite loop here
     while nin lt min_lines do begin
        ;; Expand wavelength range until we encompass enough lines.
        ;; Find the next array index beyond the current wrange
        lidx = min([inidx]) - 1
        ridx = max([inidx]) + 1
        ;; Do this one line at a time seeing which side yields the
        ;; best centering but make sure to handle the case where we
        ;; are up against a limit
        lcent = wrange[0]
        rcent = wrange[1]
        if lidx ge 0 then $
          lcent = mean([owls[lidx], wrange[1]])
        if ridx lt nidx then $
          rcent = mean([wrange[0], owls[ridx]])
        if abs(lcent - owcenter) le abs(rcent - owcenter) then $
          wrange[0] = owls[lidx] $
        else $
          wrange[1] = owls[ridx]
        inidx = where(wrange[0] le owls and owls le wrange[1], nin)
     endwhile ;; nin lt min_lines

  endfor ;; each Doppler group with enough lines

  ;; Now expand wrange to hit the first zero slope point of the model
  ;; spectrum outside the range of the included lines.
  dy = deriv(xaxis, model_spec)

  pix_idx = where(xaxis lt wrange[0], count)
  if count le 1 then begin
     message, /CONTINUE, 'WARNING: input wavelength range extends below or is too close to the edge of the model X-axis.  Line wing calculation not attempted for the left side'
  endif else begin
     ;; Find the first zero in the derivative to the left of
     ;; wrange[0].  Make sure we will have a crossing from positive to
     ;; negative.  The derivative will be 0 within a point of
     ;; wrange[0], so back off a little from that.
     if dy[pix_idx[count-1]] gt 0 then $
       dy = -dy
     cidx = where(dy[pix_idx] ge 0, count) ;; crossing idx--the max of these
     ;; Default, in case the model doesn't extend to far enough to
     ;; include a 0 crossing
     wrange[0] = min(xaxis)
     if count gt 0 then begin
        ;; unwrap
        cidx = pix_idx[cidx]
        wrange[0] = xaxis[max([cidx])]
     endif
  endelse

  pix_idx = where(xaxis gt wrange[1], count)
  if count le 1 then begin
     message, /CONTINUE, 'WARNING: input wavelength range extends above or is too close to the edge of the model X-axis.  Line wing calculation not attempted for the right side'
  endif else begin
     ;; Find the first zero in the derivative to the right of
     ;; wrange[1].  Make sure we will have a crossing from negative to
     ;; positive.  The derivative will be 0 within a point of
     ;; wrange[1], so back off a little from that.
     if dy[pix_idx[1]] lt 0 then $
       dy = -dy
     cidx = where(dy[pix_idx] le 0, count) ;; crossing idx--the min of these
     ;; Default, in case the model doesn't extend to far enough to
     ;; include a 0 crossing
     wrange[1] = max(xaxis)
     if count gt 0 then begin
        ;; unwrap
        cidx = pix_idx[cidx]
        wrange[1] = xaxis[min([cidx])]
     endif
  endelse

  return, wrange

end



