; +
; $Id: sso_dg_path.pro,v 1.1 2004/01/14 17:43:28 jpmorgen Exp $

; sso_dg_path.pro 

;; Given a Doppler group number, find the corresponding path in the
;; !sso.dgs linked list.  Return that path, or, if /names is
;; specified, the names of the objects, if they are found in the
;; !eph.names array.  An error occurs if dg does not exist in
;; !sso.dgs.

; -

function sso_dg_path, dg, names=names

  init = {sso_sysvar}
  init = {eph_sysvar}

  if N_elements(dg) eq 0 then $
    message, 'ERROR: dg must be specified'

  ;; Handle the case of a null path separately
  if dg eq !sso.null then begin
     if keyword_set(names) then $
       return, ''
     return, !sso.parinfo.sso.path
  endif

  ;; Start from the beginning of the stored list of dg/path
  ;; correspondences
  found = ptr_new()
  dgs = !sso.dgs
  while dgs ne ptr_new() do begin
     if (*dgs).dg eq dg then begin
        if found ne ptr_new() then $
          message, 'ERROR: duplicate dg numbers found in !sso.dgs'
        found = dgs
     endif
     dgs = (*dgs).next
  endwhile ;; each element in !sso.dgs
  if found eq ptr_new() then $
    message, 'ERROR: dg = ' + string(dg) + ' has not yet been assigned.  Make sure you call sso_dg_assign properly.'

  path = (*found).path
  if NOT keyword_set(names) then $
    return, path

  return, sso_path_names(path)

end
