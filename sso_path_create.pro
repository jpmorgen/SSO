; +
; $Id: sso_path_create.pro,v 1.1 2015/03/03 20:14:49 jpmorgen Exp $

; sso_path_create.pro 

;; Returns a path array in the format necessary for storing in a
;; parinfo structure or for passing to other path/dg routines.

function sso_path_create, path

  ;; Path can be an array of paths, so we might need to make an array
  ;; of arrays....  size will help us figure this out
  p_size = size(path, /structure)

  ;; Return an empty path if no path specified
  if p_size.N_elements eq 0 then $
    path = !sso.aterm

  ;; Default npath (avoids else)
  npaths = 1
  ;; The last dimension is the slowest varying one in IDL, the one
  ;; that indexes our array of arrays
  if p_size.N_dimensions gt 1 then $
    npaths = p_size.dimensions[p_size.N_dimensions-1]

  ;; Check to see if we were passed a scalar and pretend it is an
  ;; array for the code below
  if p_size.dimensions[0] eq 0 then $
    p_size.dimensions[0] = p_size.dimensions[0] + 1

  tpath = make_array(N_elements(!sso.parinfo.sso.path), npaths, $
                     value=!sso.aterm)
  ;; IDL tacks on the extra dimension (i.e. the slowest varying
  ;; subscript) to the end of the subscript list
  for i=0, npaths-1 do begin
     tpath[0:p_size.dimensions[0]-1] = path[*,i]
  endfor
  
  return, tpath

end
