; +
; $Id: sso_fmod.pro,v 1.2 2015/03/03 20:14:37 jpmorgen Exp $

; sso_fmod.pro 

;; This routine is a primitive of sso_fcreate like pfo_fmod but also a
;; stand-alone routine that turns SSO transformations on and off.  If
;; you want to do something other than modify transformations, work
;; with the structure tags directly.

;; WARNING: an entire parinfo array must be passed in order for the
;; values to be permanently changed (see IDL manual "passing by
;; reference" section).  Use the idx positional parameter to pick out
;; individual parinfo records.

; -

pro sso_fmod, parinfo, idx, ptype=ptype, ttype=ttype, dg=dg, rwl=rwl, $
              owl=owl, path=path, pfo=pfo, $
              center=center, area=area, width=width, $
              _EXTRA=extra

  ;; If we generate an error, return to the calling code.  The problem
  ;; _must_ be there, since this code is perfect ;-)
;;  ON_ERROR, 2

  ;; Pathological case, avoids lindgen(0) error
  n = N_elements(parinfo)
  if N_elements(parinfo) eq 0 then $
    return

  ;; Set up idx if none specified
  if N_elements(idx) eq 0 then $
    idx = lindgen(n)

  ;; Work with the sso part of parinfo.  We have to be careful not to
  ;; let IDL mess us up with a trivial dimension so don't use:
  ;; sso = parinfo[idx].sso
  sso = make_array(N_elements(idx), value=parinfo[0].sso)
  for i=long(0), N_elements(idx)-1 do $
     sso[i] = parinfo[idx[i]].sso

  ;; Step through the individual tags.

  if N_elements(ptype) ne 0 then begin
     struct_array_assign, sso, tagname='ptype', tagval=ptype
  endif
  if N_elements(ttype) ne 0 then begin
     struct_array_assign, sso, tagname='ttype', tagval=ttype
  endif
  if N_elements(dg) ne 0 then begin
     struct_array_assign, sso, tagname='dg', tagval=dg
  endif
  if N_elements(rwl) ne 0 then begin
     struct_array_assign, sso, tagname='rwl', tagval=rwl
  endif
  if N_elements(owl) ne 0 then begin
     struct_array_assign, sso, tagname='owl', tagval=owl
  endif

  ;; PATH
  ;;
  ;; sso.path is stored as an array with fixed length, initially
  ;; filled with -1.  Since most of the time people won't bother
  ;; putting in all the -1s, we need to do the translation here.
  if N_elements(path) ne 0 then begin
     struct_array_assign, sso, tagname='path', tagval=sso_path_create(path)
  endif

  ;; Put the modified sso structure back into parinfo.  Array brackets
  ;; are necessary to trick IDL into matching the types since the
  ;; trival array dimension gets added...
  for i=long(0), N_elements(idx)-1 do $
    parinfo[idx[i]].sso = [sso[i]]
  
  ;; Process the pfo parinfo keywords
  if N_elements(extra) ne 0 then $
    pfo_fmod, parinfo, idx, _EXTRA=extra

  ;; Exit unless we want to change the transformations
  if N_elements(center) eq 0 and $
    N_elements(area) eq 0 and $
    N_elements(width) eq 0 then $
    return

  ;; Transformations apply to lines only 
  line_idx = where(parinfo[idx].sso.ptype eq !sso.line, nline)
  if nline eq 0 then return
  ;; Unwrap indices
  line_idx = idx[line_idx]
  ;; Handle things one primitive at a time.
  fns = fix(parinfo[line_idx].sso.pfo.pfo.ftype)
  u_fns = uniq(fns, sort(fns))
  for ifn=long(0), N_elements(u_fns)-1 do begin
     fn = fns[u_fns[ifn]]
     fnidx = where(fns eq fn)
     ;; Unwrap indices
     fnidx = line_idx[fnidx]
     pname = 'sso_' + !pfo.fnames[fn]
     call_procedure, pname, parinfo, fnidx, $
                     center=center, area=area, width=width, $
                     _EXTRA=extra
  endfor


end
