; +
;; $Id: lc_read_ap.pro,v 1.1 2015/03/03 20:04:58 jpmorgen Exp $

;; lc_read_ap
;;
;; A catalogue of accurate wavelengths in the optical spectrum of the Sun
;;     Allende Prieto C., Garcia Lopez R.J.
;;    <Astron. Astrophys. Suppl. Ser. 131, 431 (1998)>
;;    =1998A&AS..131..431A      (SIMBAD/NED BibCode)
;;
;; These are fits to the peaks of the lines in Kurucz's solar
;; spectra.  Presumably the wavelengths are the best available as
;; of 1998.

;; err2lim is the factor to multiply error bars by to get parameter
;; limits.  Default=3

; -

function lc_read_ap, err2lim=err2lim, wrange=wrange

  init = {lc_sysvar}

  ;; Check to see if we have read the ASCII file once already in this
  ;; session.
  tmp = lc_read_check(!lc.ap) 
  if ptr_valid(tmp) then begin
     if N_elements(wrange) eq 0 then $
       return, (*tmp).cat

     good_idx = where(wrange[0] le (*tmp).cat.wavelen and $
                      (*tmp).cat.wavelen le wrange[1], count)
     if count eq 0 then $
       message, 'ERROR: no entries found in wavelength range'
     
     return, (*tmp).cat[good_idx]
  endif

  if N_elements(err2lim) eq 0 then $
    err2lim = 3d

  template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''			, $
        FIELDCOUNT      :		  7		, $
        FIELDTYPES      :   [5,5,5,5,7,4,4]	, $
        FIELDNAMES      :   ['lambdaD', 'e_lambdaD', 'lambdaF', 'e_lambdaF', 'Ion', 'EP', 'loggf'], $
        FIELDLOCATIONS  :   [0,10,17,27,34,38,43]	, $
        FIELDGROUPS     :   [0,1,2,3,4,5,6]}

  cd, !lc.top + '/sun/allende_prieto'
  message, /INFORMATIONAL, 'NOTE: reading ASCII table, expect delay'
  ap = read_ascii('table1.dat', template=template)

  nlines = N_elements(ap.lambdaF)
  ;; Make entries for the loggf values, which in principle could be
  ;; converted to equivalent widths
  lca = replicate(!lc.lc_struct, nlines*2)
  lca[*].cat = !lc.ap
  lca[*].src = !eph.sun
  ;; 0 = original version
  ;; lca[*].version = version

  for iap=long(0), nlines-1 do begin
     ilc = iap * 2
     ;; Use the flux spectrum
     w = ap.lambdaF[iap]
     lca[ilc:ilc+1].wavelen = w
     ;; Dump enough stuff into the name so it will hopefully be unique
     lca[ilc:ilc+1].name = ap.Ion[iap] + $
       ' EP' + strtrim(ap.EP[iap], 2) + $
       ' GF'+ strtrim(ap.loggf[iap], 2)
     lca[ilc:ilc+1].species = ap.Ion[iap]
     lca[ilc:ilc+1].ion_state = strmid(ap.Ion[iap], 2)

     lca[ilc].ptype = !lc.wavelen
     lca[ilc].value = w
     lca[ilc].error = ap.e_lambdaF[iap]
     ;; These should be generous enough to be valid no matter what
     lca[ilc].limits = [w - err2lim*lca[ilc].error, $
                        w + err2lim*lca[ilc].error]
     lca[ilc].quality = !lc.best

     ;; Equivalent width calculations depend on the molecule and are
     ;; non-trivial.  Just put negative of loggf in for now and mark
     ;; quality of this field as useless.  --> change this to -1,
     ;; since loggf is itself sometimes negative
     lca[ilc+1].ptype = !lc.ew
     ;;lca[ilc+1].value = -ap.loggf[iap]
     lca[ilc+1].value = -1
     lca[ilc+1].quality = !lc.useless
     lca[ilc+1].limits[1] = 0 ;; Don't let lines become positive
  endfor

  sidx = lc_sort(lca, /mark_dup)
  
  lca = lc_clean_dup(lca, sidx)

  ;; Put a copy of the catalog on the heap in list pointed to by
  ;; !lc.cats so we don't have to read it in next time
  tmp = {cat	: lca, $
         next: !lc.cats}
  !lc.cats = ptr_new(tmp, /allocate_heap, /no_copy)

  ;; Recursively call ourselves to use the wavelength range code
  return, lc_read_ap(wrange=wrange)

end
