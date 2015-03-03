; +
; $Id: pfo_sso_funct.pro,v 1.1 2015/03/03 20:13:45 jpmorgen Exp $

; pfo_sso_funct.pro 

;; This function is the central engine of the SSO fitting library.  It
;; is called by pfo_funct whenever a set of SSO parameters is detected
;; in a particular fseq.
; -

function pfo_sso_funct, Xin, params, dparams, parinfo=parinfo, idx=idx, $
  create=create, print=print, sso_check=sso_check, _EXTRA=extra

  ;; Generic sso and pfo system initializations
  init = {sso_sysvar}

  ;; /CREATE
  if keyword_set(create) then begin
     ;; This is just an alias for pfo_fcreate, which has lots of
     ;; command line parameters I didn't want to put into the
     ;; pfo_funct definition.
     if N_elements(ftype) eq 0 then $
       ftype=!pfo.null
     return, sso_fcreate(parinfo_template=parinfo, _EXTRA=extra)
  endif ;; /CREATE

  ;; Get active parameter indices
  f_idx = pfo_funct_check(!pfo.sso_funct, Xin=Xin, params=params, $
                          parinfo=parinfo, idx=idx, npar=npar)
  if npar eq 0 then return, pfo_null(Xin, print=print, _EXTRA=extra)

  ;; SSO_CHECK
  ;; Call sso_fcheck at this level so we can use the pfo_funct parsing
  ;; engine to separate out multiple sso functions in one parinfo 
  if keyword_set(sso_check) then begin
     sso_fcheck, parinfo, f_idx
  endif ;; SSO_CHECK


  ;; FUNCTION SPECIFIC ERROR CHECKING CODE
  if N_params() gt 2 then $
    message, 'ERROR: analytic derivatives not implemented in sso functions yet'

  ;; Get ptype indices.  Speed up code by copying only once
  sub_ptypes = parinfo[f_idx].sso.ptype
  dop_idx  = where(sub_ptypes eq !sso.dop,  ndop )
  cont_idx = where(sub_ptypes eq !sso.cont, ncont)
  line_idx = where(sub_ptypes eq !sso.line, nline)

  ;; get ttype indices
  ttypes = parinfo.sso.ttype
  c_idx = where(ttypes[f_idx] eq !sso.center and $
                finite(parinfo[f_idx].sso.rwl), nc)
  area_idx = where(ttypes[f_idx] eq !sso.area, na)
  if na gt 0 and ncont eq 0 then $
    message, 'ERROR: SSO area to equivalent-width transformation requested with no continuum specified'
  w_idx = where(ttypes[f_idx] eq !sso.width, nw)

  ;; Unnest indices
  if ndop gt 0 then $
    dop_idx = f_idx[dop_idx]
  if ncont gt 0 then $
    cont_idx = f_idx[cont_idx]
  if nline gt 0 then $
    line_idx = f_idx[line_idx]
  if nc gt 0 then $
    c_idx = f_idx[c_idx]
  if na gt 0 then $
    area_idx = f_idx[area_idx]
  if nw gt 0 then $
    w_idx = f_idx[w_idx]
  
  ;; Check proper Doppler group description
  if ndop gt 0 then begin
     u_dgs = uniq(parinfo[dop_idx].sso.dg, sort(parinfo[dop_idx].sso.dg))
     if N_elements(u_dgs) ne ndop then $
       message, 'ERROR: duplicate Doppler groups found'
  endif

  ;; Handle the null Doppler group
  dop_idx = [-1, dop_idx]
  ndop = ndop + 1

  ;; PRINTING
  ;; Print parameters in blocks according to ptype.  Except for the
  ;; Doppler shifts, use pfo_funct on the sso.pfo primitives to do the
  ;; printing.
  if keyword_set(print) then begin

     toprint = ''

     ;; Let IDL do all the error checking
;     CATCH, err
;     if err ne 0 then begin
;        CATCH, /CANCEL
;        message, /NONAME, !error_state.msg, /CONTINUE
;        message, 'ERROR: problem with print formatting'
;     endif

     ;; Make up a fake set of parinfo records that has everything we
     ;; want for printing at the top level so that we can use
     ;; pfo_funct to print them.  This is basically eveything except
     ;; ftype and the primitive parname
     pparinfo = make_array(N_elements(parinfo), value=!pfo.parinfo)
     struct_assign, parinfo, pparinfo, /NOZERO
     pparinfo.value = params
     pparinfo.pfo.ftype = parinfo.sso.pfo.pfo.ftype
     pparinfo.parname = parinfo.sso.pfo.parname

     ;; Non-null Doppler shifts
     for idg=1, ndop-1 do begin
        tidx = dop_idx[idg]
        dg = parinfo[tidx].sso.dg
        pparinfo[tidx].parname = $
          strjoin(sso_dg_path(dg, /name), '-') + $
          ' Dop'
     endfor

     ;; Delta wavelength.  To save reprinting RWL, put RWL in this
     ;; parameter only.  As long as dw is first, this should look nice
     ;; in all contexts.
     if nc gt 0 then begin
        pparinfo[c_idx].parname = $
          string(format=!sso.rwl_format, parinfo[c_idx].sso.rwl) + $
          ' dw'
     endif

     ;; Equivalent width
     if na gt 0 then begin
        pparinfo[area_idx].parname = 'ew'
     endif


;     ;; Put the rest wavelength into line parnames
;     if nline gt 0 then begin
;        rwl_idx = where(finite(parinfo[line_idx].sso.rwl), nrwl)
;        ;; This has to be done as a for loop, or else the format
;        ;; statement puts all the rwls in each parname
;        
;        for irwl=0, nrwl-1 do begin
;           tidx = line_idx[rwl_idx[irwl]]
;           ;; --> Here is where you would put things to indicate line taxonomy
;           parinfo[tidx].sso.pfo.parname = $
;             string(format=!sso.rwl_format, parinfo[tidx].sso.rwl) + $
;             ' ' + parinfo[tidx].sso.pfo.parname
;        endfor
;     endif

     ;; Tack on the parname from the top level, trimming off the extra
     ;; leading space if no upper parnames were assgned.
     pparinfo[f_idx].parname = parinfo[f_idx].parname + ' ' + $
       pparinfo[f_idx].parname
     pparinfo[f_idx].parname = strtrim(pparinfo[f_idx].parname)

     ;; Separator for unit notes
     case print of
        !pfo.ppname	:	separator = '; '
        !pfo.pmp	:	separator = !tok.newline
        else		:	separator = '; '
     endcase

     ;; Add in a note about units when we are being verbose.
     if print gt !pfo.print then begin
        if nc gt 0 then begin
           toprint = toprint + $
                     string(format='("dl=wlunits*", e6.0)', !sso.dwcvt) + $
                     separator
        endif
        if na gt 0 then begin
           toprint = toprint + $
                     string(format='("A=ew*cont*", e6.0)', !sso.ewcvt) + $
                     separator
        endif
        if nw gt 0 then begin
           toprint = toprint + $
                     string(format='("widths=wlunits*", e6.0)', !sso.lwcvt) + $
                     separator
        endif
     endif ;; printing anything other than just the parameters
     
     ;; Separator between blocks of parameters (after block and before
     ;; ptype title for next block)
     case print of
        !pfo.ppname	:	separator = '; '
        !pfo.pmp	:	separator = ''
        else		:	separator = '; '
     endcase

     ;; First print parameters that haven't been assigned to a known
     ;; ptype (e.g. instrument profile)
     oidx = where(parinfo[f_idx].sso.ptype le 0 or $
                  parinfo[f_idx].sso.ptype gt !sso.line, noidx)
     if noidx gt 0 then begin
        if keyword_set(add_separator) then $
          toprint = toprint + separator
;        if print gt !pfo.print then begin
;           toprint = toprint + 'Non-sso parameters' + hsep
;        endif
        toprint = toprint + $
                  pfo_funct(Xin, parinfo=pparinfo, idx=oidx, $
                            print=print, _EXTRA=extra)        
        add_separator = 1
     endif

     ;; Print line parameters by Doppler group.  The continuum gets
     ;; picked up automatically here as a member of the null Doppler
     ;; group.  Some continuua might eventually be Doppler shifted
     for idg=0, ndop-1 do begin
        if keyword_set(add_separator) then $
          toprint = toprint + !tok.newline

        ;; Prepare to handle the null Doppler group below
        dg = 0

        ;; Check to see if we are on a real Doppler group 
        if dop_idx[idg] ge 0 then begin
           dg = parinfo[dop_idx[idg]].sso.dg
           ;; Use pfo_null to print out this Doppler shift parameter
           toprint = toprint + $
                     pfo_null(Xin, parinfo=pparinfo, idx=dop_idx[idg], $
                              print=print, _EXTRA=extra)
        endif

        ;; Find the lines in this Doppler group
        tdg_idx = where(parinfo[f_idx].sso.dg eq dg and $
                        sub_ptypes ne !sso.dop, ntdg)
        if ntdg gt 0 then begin
           tdg_idx = f_idx[tdg_idx]
           toprint = toprint + separator
           ;; Use pfo_funct to print out the line parameters
           toprint = toprint + $
                     pfo_funct(Xin, parinfo=pparinfo, idx=tdg_idx, $
                               print=print, _EXTRA=extra)
        endif
        add_separator = 1
     endfor

     return, toprint

  endif ;; printing

  ;; CALCULATING

  ;; Assume all values used by the primitives are the same as params
  ;; and then modify those for which this is not the case.  Use the
  ;; .value field of the sso.pfo structure so I have a copy of the
  ;; actual value used for debugging purposes.
  for ipar=long(0), npar-1 do $
    parinfo[f_idx[ipar]].sso.pfo.value = params[f_idx[ipar]]

  ;; Observed wavelengths.  For atmospheric lines, the user might
  ;; specify the /center option, but not give a Doppler group.  So
  ;; make sure all centers parameters have reasonable owl values
  if nc gt 0 then begin
     parinfo[c_idx].sso.owl = parinfo[c_idx].sso.rwl
  endif

  ;; DOPPLER SHIFTS
  if ndop gt 0 then begin

     for idg=0, ndop-1 do begin
        ;; Handle the null Doppler group
        dg = 0
        dv = 0
        if dop_idx[idg] ge 0 then begin
           dg = parinfo[dop_idx[idg]].sso.dg
           dv = params[dop_idx[idg]]
        endif
        ;; find all parameters assigned to this Doppler group that
        ;; aren't the Doppler shift itself
        tdg_idx = where(parinfo[f_idx].sso.dg eq dg and $
                        sub_ptypes ne !sso.dop, ntdg)
        if ntdg eq 0 then CONTINUE ;; nothing in this Doppler group 
        tdg_idx = f_idx[tdg_idx]
        ;; find the !sso.center ttypes
        c_idx = where(ttypes[tdg_idx] eq !sso.center, nc)
        for ic=0, nc-1 do begin
           ;; CALCULATE DOPPLER SHIFT for each line center
           tc_idx = tdg_idx[c_idx[ic]]
           if finite(parinfo[tc_idx].sso.rwl) then begin
              ;; If we know the rest wavelengths, calculate the
              ;; expected observed wavelength.  The parameter we are
              ;; fitting is the delta wavelength from this expected
              ;; value.
              parinfo[tc_idx].sso.owl $
                = parinfo[tc_idx].sso.rwl * ( 1. + dv / !sso.c )
              parinfo[tc_idx].sso.pfo.value $
                = parinfo[tc_idx].sso.owl + params[tc_idx] * !sso.dwcvt
              CONTINUE
           endif ;; RWL system
           ;; We haven't specified RWL.  It is not clear to me the
           ;; best way to handle this, since I really designed things
           ;; with RWL in mind, so feel free to change this.  At the
           ;; moment I am thinking that the parameter value would be
           ;; the rest wavelegth and I can apply the Doppler shift to
           ;; that.  This is a little bit harder to constrain, but the
           ;; parameter might be fixed (if so why wouldn't it be
           ;; RWL).  Anyway, try it out.
           parinfo[tc_idx].sso.pfo.value $
             = params[tc_idx] *  ( 1. + dv / !sso.c )
        endfor ;; each line center
     endfor ;; each Doppler group
  endif ;; Processing Doppler shifts

  ;; EQUIVALENT WIDTHS
  ;;
  ;; Check for a continuum and make calculations of equivalent widths
  ;; based on the Doppler shifted positions of the lines.  Hence, this
  ;; must be done after the Doppler shifting code.  The continuum
  ;; itself could, in principle, be Doppler shifted as well
  if ncont gt 0 then begin
     ;; If we have lines with centers, we assume their parameter
     ;; values are in equivalent width, so we need to convert to real
     ;; area
     if nline gt 0 then begin
        ;; line_idx has all the line parameters
        c_idx = where(ttypes[line_idx] eq !sso.center, nc)
        if nc eq 0 then begin
           message, /informational, 'WARNING: we have things marked as lines, but no center parameters were found.'
        endif else begin
           ;c_idx = line_idx[c_idx]
           ;; Find the area parameters.  This is a bit tricky, since,
           ;; in principle, the line center parameters and the area
           ;; parameters can be scrambled.  Use rwl as the reference.
           a_idx =  where(ttypes[line_idx] eq !sso.area, na)
           for ia=0, na-1 do begin
              ta_idx = line_idx[a_idx[ia]]
              rwl = parinfo[ta_idx].sso.rwl
              dg = parinfo[ta_idx].sso.dg
              tl_idx = where(parinfo[line_idx].sso.rwl eq rwl and $
                             parinfo[line_idx].sso.dg eq dg)
              tl_idx = line_idx[tl_idx]
              temp = where(parinfo[tl_idx].sso.ttype eq !sso.center, count)
              if count eq 0 then begin
                 message, /informational, 'WARNING: area parameter specified with no corresponding center.  Equivalent with not calculated for ' + string(format=!sso.rwl_format, parinfo[ta_idx].sso.rwl)
                 CONTINUE
              endif
              ;; --> this code would be better in sso_fcheck
              if count gt 1 then $
                message, 'WARNING: more than one line found with the rwl = ' +  string(format=!sso.rwl_format, parinfo[ta_idx].sso.rwl) + ' and path = ' + '.  Equivalent width calculation might be incorrect', /informational
              tc_idx = tl_idx[temp[0]]
              ;; Calculate the continuum at the center value of the
              ;; line 
              line_cont = pfo_funct([parinfo[tc_idx].sso.pfo.value], $
                                    parinfo=parinfo[cont_idx].sso.pfo, $
                                    _EXTRA=extra)
              parinfo[ta_idx].sso.pfo.value $
                = params[ta_idx] * line_cont * !sso.ewcvt
           endfor ;; lines that have areas
        endelse ;; lines have centers
     endif ;; lines
  endif ;; continuum

  ;; LINE WIDTHS
  ;;
  ;; Assume line widths read in the same units as delta wavelength
  if nline gt 0 then begin
     w_idx = where(ttypes[line_idx] eq !sso.width, nw)
     if nw gt 0 then begin
        w_idx = line_idx[w_idx]
        parinfo[w_idx].sso.pfo.value = params[w_idx] * !sso.lwcvt
     endif
  endif

  ;; The sso.pfo.value fields should all be set.  pfo_funct will use
  ;; them to calculate the function, so params does not need to be
  ;; specified.  The default pfo function definition is a function of
  ;; xaxis, adding to the yaxis.  This is generally what I have in
  ;; mind for an absorption line spectrum, so it should work.  If the
  ;; end user wants to get fancy, they can call sso_fcreate to stuff
  ;; other values into the sso.pfo.pfo fields.  To allow for getting
  ;; fancy, let pfo_funct recalculate the continuum.  It is also
  ;; important that the Doppler shift sso.pfo.pfo.status =
  ;; !pfo.not_used, which is what pfo_null should do, so that no
  ;; futher calculations are affected by the Doppler shifts.
  return, pfo_funct(Xin, parinfo=parinfo[f_idx].sso.pfo, $
                    _EXTRA=extra)


end

