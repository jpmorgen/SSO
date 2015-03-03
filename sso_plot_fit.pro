;+

; $Id: sso_plot_fit.pro,v 1.1 2015/03/03 20:13:36 jpmorgen Exp $

;; sso_plot_fit

;; Do a pretty plot of an sso spectrum.  It is best if the calling
;; routine to figures out what the xtitle and ytitle should be e.g.:
;;
;; ;; This has to be in font !3 for the angstrom symbol to be found.
;; ;; The extra ;" is to close the " in the string
;; xtitle = 'Rest Wavelength ('+string("305B)+')' ;"
;; ytitle = string('Signal (', sxpar(hdr, 'BUNIT'), '/S)')
;;
;; dop_axis_frac is the fraction of the plot that you want to move
;; each doppler shifted axis down from the top.  The default is to put
;; the axis within 1.5 ticklen of the axis above it.
;;


;-

pro sso_plot_fit_xtitle, parinfo, idx, xtitle=xtitle, $
  full_xtitle=full_xtitle, upper_count=upper_count

  ;; This is a primitive that deals with axis titles and plotting the
  ;; Doppler shifted axes.

  ;; Doppler shifts to make alternate axes
  dop_idx = where(parinfo[idx].sso.ptype eq !sso.dop, ndop)
  ;; unnest
  if ndop gt 0 then $
    dop_idx = idx[dop_idx]
    

  ;; Put Doppler shifted axis names into main axis title
  full_xtitle = ''
  upper_count = 0
  for idop=0, ndop-1 do begin
     dop = parinfo[dop_idx[idop]].value ; Doppler shift
     ;; --> Don't bother with axes that are at rest.  There is an
     ;; implicit assumption here that the main xaxis is the rest axis.
     if dop eq 0 then $
       CONTINUE
     dg = parinfo[dop_idx[idop]].sso.dg ; Doppler group
     line_idx = where(parinfo[idx].sso.dg eq dg and $
                      parinfo[idx].sso.ttype eq !sso.center, nlines)
     ;; Don't bother with axis 
     if nlines lt !sso.min_lines then $
       CONTINUE
     full_xtitle = full_xtitle + ' ' + $
                   strjoin(sso_dg_path(dg, /name), '-') + ' (upper'
     if upper_count gt 0 then $
       full_xtitle = full_xtitle + '-' + strtrim(upper_count, 2)
     full_xtitle = full_xtitle + ')'
     upper_count = upper_count + 1
  endfor
  if upper_count eq 0 then begin
     full_xtitle = xtitle
  endif else begin
     full_xtitle = xtitle + ' (lower)' + full_xtitle
  endelse

  return
end

pro sso_plot_fit_axes, parinfo, idx, xaxis, xrange, upper_count=upper_count, $
  dop_axis_frac=dop_axis_frac

  ;; Make Doppler shifted axes on the current plot frame.  These start
  ;; at the top and work their way down.

  dop_idx = where(parinfo[idx].sso.ptype eq !sso.dop, ndop)
  if ndop eq 0 then $
    return
  dop_idx = idx[dop_idx]

  ;; Estimate the wavelength reference value from the X-axis.
  ;; Ideally, we should dig into the dispersion and grab its reference
  ;; value, but for plotting, this is good enough.  Keep the code
  ;; general.
  wave_shifts = parinfo[dop_idx].value/!sso.c * median(xaxis)

  total_y = !y.crange[1] - !y.crange[0]
  ;; !p.ticklen reads in device units
  ydelta = 3 * !p.ticklen * total_y
  if keyword_set(dop_axis_frac) then begin
     ydelta = (total_y) * dop_axis_frac
  endif
  if upper_count * ydelta gt total_y then $
    message, 'WARNING: not enough room for all the Doppler shifted axes'
  upper_count = 0
  for idop=0, ndop-1 do begin
     dg = parinfo[dop_idx[idop]].sso.dg ; Doppler group
     line_idx = where(parinfo[idx].sso.dg eq dg and $
                      parinfo[idx].sso.ttype eq !sso.center, nlines)
     ;; Skip axes for case where we have just a few lines (this will
     ;; turn out to be Io [OI] or Na.  Also skip for things that are
     ;; in the rest frame
     if nlines lt !sso.min_lines or parinfo[dop_idx[idop]].value eq 0 then $
       CONTINUE
     ;; We have an axis with plenty of lines (e.g. solar)
     axis, !x.crange[0], !y.crange[1] - ydelta * upper_count, $
           xrange=xrange-wave_shifts[idop], xaxis=0, xstyle=!tok.exact, $
           ticklen=-!p.ticklen
     upper_count = upper_count + 1
  endfor
  
end

pro sso_plot_fit_special, pix_axis, params, parinfo, idx, xrange, $
  spec, err_spec, rpsym

  ;; Overplot the contiuum without special lines (if they are in the
  ;; parameter list) and plot a vertical line indicating position of
  ;; each special line (whether or not they are in the parameter list)

  if !sso.special_lines eq ptr_new() then $
    return

  ;; Make a copy of !sso.special_lines so we can mess with it
  special_lines = *!sso.special_lines

  ;; Make a temporary parinfo array to play with.  Make sure to take
  ;; values from params.
  tparinfo = parinfo[idx]
  tparinfo.value = params[idx]

  ;; Copy off !sso.dgs do we don't mess it up with special lines we
  ;; don't have in tparinfo
  save_sso_dgs = !sso.dgs
  !sso.dgs = ptr_new()

  ;; Find out how many Doppler shift parameters we have for warning below
  sso_dg_assign, tparinfo
  dop_idx = where(tparinfo.sso.ptype eq !sso.dop, ndop)

  ;; Assign the parinfo Doppler groups to the special lines so we can
  ;; match then.  Check to see if we have all the Doppler parameters
  ;; we need.
  if ndop gt 0 then $
    special_lines = array_append(special_lines, tparinfo[dop_idx])
  sso_dg_assign, special_lines, count=count
  if count ne ndop then $
    message, 'WARNING: Your input parinfo does not have Doppler shifts assigned for all your special lines.  Some of them will be plotted with 0 Doppler shift. ', /CONTINUE

  ;; Match special lines to any lines in [t]parinfo.  The tparinfo
  ;; side of the match is special_idx, the special is matched_idx
  special_idx = !values.d_nan
  matched_idx = !values.d_nan

;; --> I think I need to work with just the central wavelengths

  spec_lc_idx = where(special_lines.sso.ttype eq !sso.center, nsp)
  for isp=0, nsp-1 do begin
     rwl = special_lines[spec_lc_idx[isp]].sso.rwl
     dg = special_lines[spec_lc_idx[isp]].sso.dg
     midx = where(tparinfo.sso.rwl eq rwl and $
                  tparinfo.sso.dg  eq dg, nmatch)
     if nmatch eq 0 then $
       CONTINUE
     special_idx = array_append(midx, special_idx)
     sidx = where(special_lines.sso.rwl eq rwl and $
                  special_lines.sso.dg  eq dg)
     matched_idx = array_append(sidx, matched_idx)
  endfor

  ;; Default case: we have no special lines in tparinfo yet.  Get
  ;; ready to add them (but avoid non-line parameters).  We modify
  ;; this below
  no_match_idx = where(special_lines.sso.ptype eq !sso.line, n_no_match)

  ;; If we found any special lines, remove them from tparinfo and plot
  ;; everything else.
  if finite(special_idx[0]) then begin
     tparinfo[special_idx].pfo.status = !pfo.inactive
     model_spec = pfo_funct(pix_axis, parinfo=tparinfo, xaxis=xaxis)
     ;; Passing spec is the hint that we want to plot residuals
     if keyword_set(spec) then begin
        ;; Check to see if we want to put plotting symbols onto the
        ;; errorbars (analog of residuals section 
        resid = spec - model_spec
        sso_oploterr, xaxis, resid, err_spec, rpsym, linestyle=!tok.dotted
     endif else begin
        oplot, xaxis, model_spec, linestyle=!tok.dotted
     endelse


     tparinfo[special_idx].pfo.status = !pfo.active

     ;; Get ready to plot vertical lines by appending non-matching
     ;; special lines to tparinfo and updating special_idx.  There
     ;; seems to be no shorthand way of doing this
     no_match_idx = !values.f_nan
     n_no_match = 0
     for isidx=0, N_elements(special_lines)-1 do begin
        junk = where(isidx eq matched_idx, count)
        if count ne 0 or $
          special_lines[isidx].sso.ptype ne !sso.line then $
          CONTINUE
        no_match_idx = array_append(isidx, no_match_idx)
        n_no_match = n_no_match + 1
     endfor
  endif ;; found matching special lines

  ;; Make sure we do calculations for non-matching lines we may have
  ;; added to tparinfo
  if n_no_match gt 0 then begin
     special_idx = array_append(indgen(n_no_match) + N_elements(tparinfo), $
                                special_idx)
     tparinfo = array_append(special_lines[no_match_idx], tparinfo)
     model_spec = pfo_funct(pix_axis, parinfo=tparinfo, xaxis=xaxis)
  endif

  ;; Plot vertical lines at special line wavelengths
  good_idx = where(xrange[0] lt tparinfo[special_idx].sso.owl and $
                   tparinfo[special_idx].sso.owl lt xrange[1] and $
                   tparinfo[special_idx].sso.ttype eq !sso.center, nlines)
  for il=0, nlines-1 do begin
     ;; unwrap
     tidx = special_idx[good_idx[il]]
     owl = tparinfo[tidx].sso.owl
     dg = tparinfo[tidx].sso.dg
     rwl = tparinfo[tidx].sso.rwl
     parname = tparinfo[tidx].parname
     plots, [1d,1d]*owl, !y.crange, linestyle=!tok.dashed
     xyouts, owl, mean(!y.crange[0]), ' ' + $
             strjoin(sso_dg_path(dg, /name), '-') + $
             parname + ' ' + string(format=!sso.rwl_format, rwl), $
             orientation=90, charsize=0.75

  endfor ;; Each special line

  ;; Put back Doppler groups
  sso_dg_assign, /clear
  !sso.dgs = save_sso_dgs

  return
end


pro sso_plot_fit, pix_axis, parinfo, params=params, idx=idx, spec, err_spec, $
                  xrange=inxrange, yrange=inyrange, $
                  resid_yrange=inresid_yrange, $
                  title=intitle, xtitle=inxtitle, ytitle=inytitle, $
                  dop_axis_frac=dop_axis_frac, _EXTRA=extra

  init = {sso_sysvar}
  init = {tok_sysvar}

  ;; idx might not have been specified
  if N_elements(idx) eq 0 then $
    idx = lindgen(N_elements(parinfo))

  if NOT keyword_set(params) then $
    params = parinfo.value
  
  if N_elements(params) ne N_elements(parinfo) then $
    message, 'ERROR: params and parinfo are not the same length.  Pass the whole arrays and let idx= take care of selecting the things you want'

  ;; Get the active parameters
  f_idx = where(parinfo[idx].pfo.status eq !pfo.active, npar)
  if npar eq 0 then begin
     message, 'WARNING: no active parameters in function, not plotting anything', /CONTINUE
  endif
  ;; unnest
  f_idx = idx[f_idx]

  ;; Calculate the model spectrum + extract the X axis
  model_spec = pfo_funct(pix_axis, params, parinfo=parinfo, idx=f_idx, $
                         xaxis=xaxis)

  ;; Get the continuum level for plotting right hand axis (default to
  ;; max of model if no continuum in model)
  cont = max(model_spec)
  cont_idx = where(parinfo[f_idx].sso.ptype eq !sso.cont, ncont)
  disp_idx = where(parinfo[f_idx].pfo.inaxis eq !pfo.Xin and $
                   parinfo[f_idx].pfo.outaxis eq !pfo.Xaxis, ncont)
  if ncont gt 0 and ncont gt 0 then begin
     cont_idx = f_idx[cont_idx]
     disp_idx = f_idx[disp_idx]
     cont_spec = pfo_funct(pix_axis, params, parinfo=parinfo, $
                           idx=[disp_idx, cont_idx])
     tmp = pfo_funct([median(pix_axis)], params, parinfo=parinfo, $
                      idx=[disp_idx, cont_idx])
     cont = tmp[0]
  endif

  residual = spec - model_spec
  av_resid = residual
  if N_elements(pix_axis) gt 5 then $
    av_resid = smooth(residual, 5)

  if keyword_set(inxrange) then $
    xrange = inxrange $
  else $
    xrange = [min(xaxis), max(xaxis)]

  if keyword_set(inyrange) then $
    yrange = inyrange $
  else $
    yrange = [min(spec), max(spec)]

  if keyword_set(inresid_yrange) then $
    resid_yrange = inresid_yrange $
  else $
    resid_yrange = [min(residual), max(residual)]
  ;; try to bump out the residual axis range a little for plotting
  ;; special residuals
  rdelta = resid_yrange[1] - resid_yrange[0]
  resid_yrange=[resid_yrange[0] - 0.2*rdelta, $
                resid_yrange[1] + 0.2*rdelta]

  if keyword_set(intitle) then $
    title = intitle $
  else $
    title = 'please supply title= keyword to sso_plot_fit'

  if keyword_set(inxtitle) then $
    xtitle = inxtitle $
  else $
    xtitle = 'Rest Wavelength'

  if keyword_set(inytitle) then $
    ytitle = inytitle $
  else $
    ytitle = 'Signal'

  ;; Put the residuals window first so the mouse events get
  ;; registered with the correct x-axis

  nbins = round(N_elements(xaxis)/10.)
  if nbins gt 2 then begin
     hist = histogram(residual/median(err_spec), nbins=nbins, omin=omin, omax=omax)
     binsize = (omax-omin)/(nbins-1)
     hist_xaxis = lindgen(nbins)*binsize + omin + binsize/2.
     plot, hist_xaxis, hist, psym=!tok.hist, position=[0.8, 0.4, 0.95, 0.6], $
           title='Histogram of residuals', charsize=0.75, $
           xtitle='Sigma', ytitle='Number in bin'
     ;; plot a Gaussian of an ideal parent population
     oplot, hist_xaxis, N_elements(xaxis)*binsize/sqrt(2*!pi) * exp(-hist_xaxis^2/2.), linestyle=!tok.dashed

     !p.multi = [2,0,2]
  endif else $
    !p.multi = [0,0,2]

  ;; Call a primitive to handle ugly axis title stuff
  sso_plot_fit_xtitle, parinfo, f_idx, xtitle=xtitle, full_xtitle=full_xtitle, $
                       upper_count=upper_count
  
  xstyle = !tok.exact
  if upper_count gt 0 then $
    xstyle = xstyle + !tok.no_box

  ;; SPECTRUM
  plot, xaxis, spec, psym=!tok.dot, title=title, $
        xtitle=full_xtitle, ytitle=ytitle, xrange=xrange, yrange=yrange, $
        xstyle=xstyle, ystyle=!tok.extend+!tok.no_box, xmargin=[8,8]
  axis, !x.crange[1], !y.crange[0], /yaxis, yrange=!y.crange/cont, $
        ytitle='Fraction of continuum', ystyle=!tok.exact

  oploterr, xaxis, spec, err_spec, !tok.dot
  oplot, xaxis, model_spec, linestyle=!tok.dash_dot

  ;; Continuum
  oplot, xaxis, cont_spec, linestyle=!tok.dotted, color=40
  

  ;; Add Doppler shifted axes and special lines
  sso_plot_fit_axes, parinfo, f_idx, xaxis, xrange, upper_count=upper_count, $
                     dop_axis_frac=dop_axis_frac
  sso_plot_fit_special, pix_axis, params, parinfo, f_idx, xrange


  ;; RESIDUALS.  Put the signal on the left axis and sigma on the right
  plot, xaxis, residual, psym=!tok.dot, title='Fit Residuals', $
        xtitle=full_xtitle, ytitle=ytitle, $
        xrange=xrange, yrange=resid_yrange, $
        xstyle=xstyle, ystyle=!tok.extend+!tok.no_box, xmargin=[8,8]
  ;; Save plotted yrange
  rdelta = !y.crange[1] - !y.crange[0]
  axis, !x.crange[1], !y.crange[0], /yaxis, yrange=!y.crange/median(err_spec), $
        ytitle='Sigma', ystyle=!tok.exact
  
  ;; Plot asterisks to mark the residual centers if they are not going
  ;; to dominate the errorbars
  psym = !tok.dot
  rpsym = !tok.dot
  if rdelta lt 20 * median(err_spec) then begin
     psym = !tok.asterisk
     rpsym = !tok.plus
  endif
  oploterr, xaxis, residual, err_spec, psym
  oplot, xaxis, av_resid, linestyle=!tok.solid

  ;; Add Doppler shifted axes and special lines
  sso_plot_fit_axes, parinfo, f_idx, xaxis, xrange, upper_count=upper_count, $
                     dop_axis_frac=dop_axis_frac
  sso_plot_fit_special, pix_axis, params, parinfo, f_idx, xrange, $
    spec, err_spec, rpsym


  !p.multi = 0
  return

end
