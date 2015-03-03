; +
; $Id: sso_null.pro,v 1.1 2015/03/03 20:17:30 jpmorgen Exp $

; sso_null.pro 

;; Each pfo primitive used as an sso primitive needs a routine to
;; indicate which parameters normally undergo an sso transformation.
;; Since this is the null proceedure, it basically does nothing,
;; though I suppose it could be used to initialize the sso system if
;; you don't like init = {sso_sysvar}

; -

pro sso_null, parinfo, idx, _EXTRA=extra

  ;; Generic sso system initialization
  init = {sso_sysvar}

  return

end
