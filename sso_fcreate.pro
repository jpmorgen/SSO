; +
; $Id: sso_fcreate.pro,v 1.1 2004/01/14 17:37:32 jpmorgen Exp $

; sso_fcreate.pro 

;; Create an array of parinfo records for the desired sso/pfo
;; function.  This is basically a wrapper for pfo_fcreate that sets
;; the sso-specific fields in the parinfo structure.  At the moment,
;; Doppler shifts are prepended automatically every time this is
;; called.  If you want to explicitly add a Doppler shift parameter to
;; a function you have been piecing together, prepend it and all
;; subsequent ones will be ignored.

; -

function sso_fcreate, pptype, parinfo_template=parinfo_template, $
  ptype=ptype, path=path, ftype=inftype, rwl=rwl, _EXTRA=extra
                     
  init = {sso_sysvar}

  ;; Error checking
  if N_elements(pptype) ne 0 then begin
     if N_elements(ptype) ne 0 then $
       if pptype ne ptype then $
       message, 'ERROR: both ptype= and the positional parameter pptype are specified but disagree.  pptype = ' + string(pptype) + ' ptype = ' + string(ptype)
     ptype = pptype
  endif
  if NOT keyword_set(ptype) then $
    message, 'ERROR: ptype must be specified (see documentation)'

  ;; CURRENTLY DEFINED PARAMETER TYPES
  if ptype lt !sso.dop or ptype gt !sso.line then $
    message, 'ERROR: parameter type ' + string(ptype) + ' not recognized. '

  ;; Make sure ftype is set to something so call to pfo_fcreate below
  ;; doesn't fail.  Doppler parameters are handled by pfo_sso_funct
  ;; and so have a null sso.pfo.pfo.ftype.  Use inftype to make sure
  ;; not to modify calling program's ftype.  Note that it is handy
  ;; that pfo_null sets pfo.status=!pfo.not_used, so Doppler shifts
  ;; don't confuse the pfo_funct call on sso.pfo
  if N_elements(inftype) eq 0 then $
    inftype = !pfo.null
  ftype = inftype
  if ptype eq !sso.dop then $
    ftype = !pfo.null

  ;; CURRENTLY DEFINED PRIMITIVES
  if ftype lt !pfo.null or ftype gt !pfo.voigt then $
    message, 'ERROR: function type ' + string(ftype) + ' is not a valid sso primitive.  Feel free to fix this deficiency.'

;  ;; Pick and standard format for displaying parameters and their errors
;  if NOT keyword_set(format) then $
;    format = 'f8.2'
;  if NOT keyword_set(eformat) then $
;    eformat = 'e8.1'

  ;; pfo will become a pure pfo_parinfo record that will get copied
  ;; into the pfo branch of the sso_parinfo structure.  All of the
  ;; formatting stuff in _EXTRA will get put into the primitive.  Use
  ;; pfo_fcreate with ftype=!pfo.sso_funct to get the formatting to
  ;; apply to the sso parameters.
  prim = pfo_fcreate(ftype, format=format, eformat=eformat, _EXTRA=extra)
  npar = N_elements(prim)

  ;; Make sure we have a parinfo template that has the sso structure
  ;; in it.  If parinfo_template was specified, but has no sso
  ;; structure, append one.
  if NOT keyword_set(parinfo_template) then $
    parinfo_template = !sso.parinfo
  junk = where(tag_names(parinfo_template) eq 'SSO', issso)
  if issso eq 1 then begin
     parinfo = parinfo_template
  endif else begin
     sso_struct__define, sso_struct=sso_struct
     sso = {sso : sso_struct}
     ;; Make new parinfo an anonymous structure, in case we are
     ;; defining many such structures
     parinfo = struct_append(parinfo_template, sso)
  endelse

  ;; Set the sso fields of the new parinfo structure to the default
  ;; values
  struct_assign, !sso.parinfo, parinfo

  ;; Make npar sso parinfo records
  parinfo = replicate(parinfo[0], npar)

  ;; Copy the primitive into the top level and into the sso.pfo
  struct_assign, prim, parinfo, /NOZERO
  for ip=0, npar-1 do begin
     parinfo[ip].sso.pfo = prim[ip]
  endfor
  
  ;; Fill in the sso part of parinfo
  parinfo.pfo.ftype = !pfo.sso_funct
  ;; Clear out the top level parname, since pfo_sso_funct adds what is
  ;; there to modified versions of the primitive parnames
  parinfo.parname = ''
  sso_fmod, parinfo, ptype=ptype, ttype=ttype, dg=dg, rwl=rwl, $
            owl=owl, path=path, pfo=pfo, $
            center=center, area=area, width=width, $
            _EXTRA=extra

  sso_fcheck, parinfo

  return, parinfo

end
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  parinfo.sso.ptype = ptype
;;
;;  ;; RWL (rest wavelength)
;;  if keyword_set(rwl) then begin
;;     parinfo[*].sso.rwl = rwl
;;;     parinfo[*].parname = string(format='(f9.4, " ")', rwl) + $
;;;                       parinfo[*].parname
;;  endif ;; RWL
;;
;;  
;;  ;; --> consider making the code below more modular, since assigning
;;  ;; and unassigning generic parameter attributes would be a useful
;;  ;; user-level thing to do.
;;  if ftype gt !pfo.poly and ftype le !pfo.voigt then begin
;;     dftype = parinfo.sso.pfo.pfo.ftype - ftype
;;     ;; A bit of a hack.  It would be better to have primitives
;;     ;; matched to each function (e.g. sso_voigt) that took care of
;;     ;; this.
;;     junk = where(dftype le !sso.width, count)
;;     if count eq 0 then $
;;       message, 'ERROR: ftype ' + string(ftype) + ' possibly named ' + !pfo.fnames[ftype] + ' does not seem to have center, area, or width definitions.'
;;     c_idx = where(!sso.center-!sso.small lt dftype and $
;;                   dftype lt !sso.center+!sso.small, count)
;;     if count gt 0 then begin
;;        parinfo[c_idx].sso.ptype = parinfo[c_idx].sso.ptype + !sso.center
;;        parinfo[c_idx].parname = 'dl'
;;     endif
;;     a_idx = where(!sso.area-!sso.small lt dftype and $
;;                   dftype lt !sso.area+!sso.small, count)
;;     if count gt 0 then begin
;;        parinfo[a_idx].sso.ptype = parinfo[a_idx].sso.ptype + !sso.area
;;        parinfo[a_idx].parname = 'ew'
;;     endif
;;
;;     ;; This is a total hack, but does work for 'deltafn', 'gauss',
;;     ;; 'voigt' and will probably work if I add lor
;;     w_idx = where(dftype gt !sso.width-!sso.small, count)
;;     if count gt 0 then begin
;;        parinfo[w_idx].sso.ptype = parinfo[w_idx].sso.ptype + !sso.width
;;     endif
;;
;;  endif ;; pfo primitives delta through voigt 
;;
;;  parinfo.parname = !sso.ptnames[ptype] + ' ' + parinfo.parname
;;
;;  ;; PATH
;;  npath = N_elements(path)
;;  if npath gt N_elements(parinfo[0].sso.path) then $
;;    message, 'ERROR: supplied path has too many elements.  See sso_struct_define.pro to increase number of path elements'
;;  if npath gt 0 then begin
;;     ;; Make Doppler group assignments
;;     parinfo[*].sso.path[0:npath-1] = path[*]
;;     sso_dg_assign, parinfo
;;  endif ;; PATH
;;
;;  return, parinfo
;;
;;end
