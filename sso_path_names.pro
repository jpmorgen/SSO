; +
; $Id: sso_path_names.pro,v 1.1 2004/01/14 17:42:59 jpmorgen Exp $

; sso_path_names.pro 

;; Returns string values for the objects in the path.  Default to a
;; string version of the path number itself and then try to look up
;; that number in !eph.names.  This code is slow, since it uses
;; array_append, but there should never be large numbers of elements
;; in path.

function sso_path_names, path, string=string

  ip = 0
  apath = 0
  while path[ip] ne !sso.aterm do begin
     spath = strtrim(path[ip], 2)
     if path[ip] lt N_elements(!eph.names) then $
       if !eph.names[path[ip]] ne '' then $
       spath = !eph.names[path[ip]]
     apath = array_append(spath, apath)
     ip = ip + 1
  endwhile
  
  return, apath

end
