; +
;; $Id: lc_build_sso.pro,v 1.4 2015/03/03 20:07:50 jpmorgen Exp $

;; lc_build_sso
;;
;; Build up the sso line catalog

; -

function lc_build_sso, maxdiff=maxdiff, wrange=wrange, xrange=xrange, $
  nclose=nclose, milli=milli

  init = {lc_sysvar}
  init = {sso_sysvar}
  init = {tok_sysvar}

  if N_elements(wrange) eq 0 then $
    wrange = [6000, 6600]

  moore = lc_read_moore(wrange=wrange)
  pb = lc_read_pb(wrange=wrange)
  ap = lc_read_ap(wrange=wrange)
;  kurucz = lc_read_kurucz(wrange=wrange)
  hitran = lc_read_hitran(wrange=wrange)

  if not keyword_set(xrange) then $
    xrange = wrange

  window, 0
  lc_match_two, moore, pb, maxdiff=maxdiff, xrange=xrange, nclose=nclose, $
                milli=milli
  sso = lc_merge_two(moore, pb, !lc.sso)

  window, 1
  lc_match_two, ap, sso, maxdiff=maxdiff, xrange=xrange, nclose=nclose, $
                milli=milli
  sso = lc_merge_two(ap, sso, !lc.sso)

;  window, 2
;  lc_match_two, sso, kurucz, maxdiff=maxdiff, xrange=xrange, nclose=nclose, $
;                milli=milli
;  sso = lc_merge_two(sso, kurucz, !lc.sso)

  window, 3
  lc_match_two, sso, hitran, maxdiff=maxdiff, xrange=xrange, nclose=nclose, $
                milli=milli
  sso = lc_merge_two(sso, hitran, !lc.sso)

  return, sso

end
