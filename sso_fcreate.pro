; +
; $Id: sso_fcreate.pro,v 1.2 2015/03/03 20:15:25 jpmorgen Exp $

; sso_fcreate.pro 

;; Create an array of parinfo records for the desired sso/pfo
;; function.  This is basically a wrapper for pfo_fcreate that sets
;; the sso-specific fields in the parinfo structure.  Doppler shifts
;; are prepended automatically every time this is called unless you
;; specify the /no_check option.

; -

function sso_fcreate, pptype, parinfo_template=parinfo_template, $
  ptype=ptype, path=path, sso_ftype=inftype, rwl=rwl, no_check=no_check, $
  _EXTRA=extra
                     
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
  sso_ftype = inftype
  if ptype eq !sso.dop then $
    sso_ftype = !pfo.null

  ;; CURRENTLY DEFINED PRIMITIVES
  if sso_ftype lt !pfo.null or sso_ftype gt !pfo.voigt then $
    message, 'ERROR: function type ' + string(sso_ftype) + ' is not a valid sso primitive.  Feel free to fix this deficiency.'

;  ;; Pick and standard format for displaying parameters and their errors
;  if NOT keyword_set(format) then $
;    format = 'f8.2'
;  if NOT keyword_set(eformat) then $
;    eformat = 'e8.1'

  ;; Raise an error if the user is trying to make more than one line
  ;; at a time  
  n_rwl = N_elements(rwl)
  if n_rwl gt 0 then begin
     u_rwl = uniq(rwl, sort(rwl))
     n_urwl = N_elements(u_rwl)
     if n_urwl ne n_rwl then $
       message, 'ERROR: Rest wavelengths don''t match.  Are you trying to create more than one line at a time?  If so, make a loop in the calling routine.'
  endif

  ;; pfo will become a pure pfo_parinfo record that will get copied
  ;; into the pfo branch of the sso_parinfo structure.  All of the
  ;; formatting stuff in _EXTRA will get put into the primitive.  Use
  ;; pfo_fcreate with sso_ftype=!pfo.sso_funct to get the formatting to
  ;; apply to the sso parameters.
  prim = pfo_fcreate(sso_ftype, format=format, eformat=eformat, _EXTRA=extra)
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
  struct_assign, !sso.parinfo, parinfo, /NOZERO

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

  if NOT keyword_set(no_check) then $
    sso_fcheck, parinfo

  return, parinfo

end
