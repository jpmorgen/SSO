; +
; $Id: sso_fmod.pro,v 1.1 2004/01/14 17:41:16 jpmorgen Exp $

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

  ;; Pathological case, avoids indgen(0) error
  n = N_elements(parinfo)
  if N_elements(parinfo) eq 0 then $
    return

  ;; Set up idx if none specified
  if N_elements(idx) eq 0 then $
    idx = indgen(n)

  ;; Work with the sso part of parinfo.  We have to be careful not to
  ;; let IDL mess us up with a trivial dimension so don't use:
  ;; sso = parinfo[idx].sso
  sso = make_array(N_elements(idx), value=parinfo[0].sso)
  for i=0, N_elements(idx)-1 do $
     sso[i] = parinfo[idx[i]].sso

  ;; Step through the individual tags.

  if keyword_set(ptype) then begin
     struct_array_assign, sso, tagname='ptype', tagval=ptype
  endif
  if keyword_set(ttype) then begin
     struct_array_assign, sso, tagname='ttype', tagval=ttype
  endif
  if keyword_set(dg) then begin
     struct_array_assign, sso, tagname='dg', tagval=dg
  endif
  if keyword_set(rwl) then begin
     struct_array_assign, sso, tagname='rwl', tagval=rwl
  endif
  if keyword_set(owl) then begin
     struct_array_assign, sso, tagname='owl', tagval=owl
  endif

  ;; PATH
  ;;
  ;; sso.path is stored as an array with fixed length, initially
  ;; filled with -1.  Since most of the time people won't bother
  ;; putting in all the -1s, we need to do the translation here.
  if keyword_set(path) then begin
     ;; Path can be an array of paths, so we might need to make an
     ;; array of arrays....
     p_size = size(path, /structure)
     if p_size.N_dimensions eq 1 then $
       npaths = 1 $
     else $
       npaths = p_size.dimensions[p_size.N_dimensions-1]
     tpath = make_array(N_elements(!sso.parinfo.sso.path), npaths, $
                        value=!sso.aterm)
     ;; IDL tacks on the extra dimension (i.e. the slowest varying
     ;; subscript) to the end of the subscript list
     for i=0, npaths-1 do begin
        tpath[0:p_size.dimensions[0]-1] = path[*,i]
     endfor

     ;; Now we are ready to do the assignment
     struct_array_assign, sso, tagname='path', tagval=path
  endif

  ;; Put the modified sso structure back into parinfo.  Array brackets
  ;; are necessary to trick IDL into matching the types since the
  ;; trival array dimension gets added...
  for i=0, N_elements(idx)-1 do $
    parinfo[idx[i]].sso = [sso[i]]
  
  ;; Process the pfo parinfo keywords
  if keyword_set(extra) then $
    pfo_fmod, parinfo, idx, _EXTRA=extra
  
  ;; Exit unless we want to change the transformations
  if NOT ( keyword_set(center) or $
           keyword_set(area) or $
           keyword_set(width) ) then $
    return

  ;; Transformations apply to lines only 
  line_idx = where(parinfo.sso.ptype[idx] eq !sso.line, nline)
  if nline eq 0 then return
  ;; Unwrap indices
  line_idx = idx[line_idx]
  ;; Handle things one primitive at a time.
  fns = fix(parinfo[line_idx].sso.pfo.pfo.ftype)
  u_fns = uniq(fns, sort(fns))
  for ifn=0, N_elements(u_fns)-1 do begin
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
