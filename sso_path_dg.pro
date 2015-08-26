; +
; $Id: sso_path_dg.pro,v 1.2 2015/03/03 20:15:58 jpmorgen Exp $

; sso_path_dg.pro 

;; Returns the Doppler group number in the !sso.dgs linked list
;; corresponding to the supplied path.  If path is not found, -1 is
;; returned.

; -

function sso_path_dg, path

  init = {sso_sysvar}

  if N_elements(path) eq 0 then $
     mesaage, 'ERROR: path required'

  ;; Return the sso null path (0) if the input path is not set
  t = where(path eq !sso.aterm, npath)
  if npath eq 0 then begin
     message, 'ERROR: Hey, fix this bug!  The path was initilized to 0, not -1', /continue
     return, !sso.null
  endif
  p_len = t[0]
  if p_len eq 0 then $
    return, !sso.null

  dg = -1
  ;; Start from the beginning of the stored list of dg/path
  ;; correspondences
  dgs = !sso.dgs
  while dgs ne ptr_new() do begin
     ;; Just in case there is junk after the array terminator, make
     ;; sure to take only the good part of each array
     t = where((*dgs).path eq !sso.aterm)
     dgs_p_len = t[0]
     if dgs_p_len eq 0 then $
       message, 'ERROR: a null path entry snuck into the !sso.dgs list.  Consider clearing with sso_dg_assign, /clear'
     if dgs_p_len eq p_len then begin
        ;; Use IDL's array method of comparisons (array elements are
        ;; compared sequentially and a vector of boolean results returned)
        test = (*dgs).path[0:dgs_p_len-1] eq path[0:p_len-1]
        if total(test) eq dgs_p_len then begin
           ;; We have an exact match
           if dg ne -1 then $
             message, 'ERROR: duplicate paths found in !sso.dgs'
           dg = (*dgs).dg
        endif ;; exact match
     endif ;; equal lengths
     dgs = (*dgs).next
  endwhile ;; each element in !sso.dgs

  return, dg

end
