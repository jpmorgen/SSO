; +
; $Id: sso_parinfo__define.pro,v 1.1 2004/01/14 17:39:28 jpmorgen Exp $

; sso_parinfo__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; Add on the sso specific tags to the pfo_parinfo structure.  Do this
;; with a single tag sso that refers to a structure so as to keep the
;; top parinfo level clean.

pro sso_parinfo__define, parinfo=parinfo
  pfo_parinfo__define, parinfo=pfo_parinfo
  sso_struct__define, sso_struct=sso_struct
  sso = {sso : sso_struct}
  parinfo = struct_append(pfo_parinfo, sso, name="sso_parinfo")

end
