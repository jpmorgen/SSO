; +
;; $Id: lc_read_huestis.pro,v 1.1 2015/03/03 20:08:25 jpmorgen Exp $

;; lc_read_huestis 
;; These values were provided by David Huestis and are gleaned from
;; Naus et al Spectrochimica Acta A 55, 1255 (1999).  Naus et al quote
;; an accuracy of 0.01 1/cm


; -

function lc_read_huestis, err2lim=err2lim, wrange=wrange

  init = {lc_sysvar}

  ;; Check to see if we have read the ASCII file once already in this
  ;; session.
  tmp = lc_read_check(!lc.huestis) 
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
    DATASTART       :		  2 		, $
    DELIMITER       :	  ''	    		, $
    MISSINGVALUE    :		 !values.f_nan	, $
    COMMENTSYMBOL   :   ''			, $
    FIELDCOUNT      :		  4		, $
    FIELDTYPES      :   [5,5,4,7]	, $
    FIELDNAMES      :   ['wavenum', 'T1', 'T2', 'T3'],$
    FIELDLOCATIONS  :   [3,15,27,33]	, $
    FIELDGROUPS     :   [0,1,2,3]}

  cd, !lc.top + '/O2'
  ;; This is very short for now
  ;; message, /INFORMATIONAL, 'NOTE: reading ASCII table, expect delay'

  o2=read_ascii('egamma.dat', template=template)

  ;; Make an lc array with one elements per line
  nlines = N_elements(o2.wavenum)
  lca = replicate(!lc.lc_struct, nlines)
  lca[*].cat = !lc.huestis
  lca[*].src = !eph.earth
  lca[*].species = 'O2'
  lca[*].name = 'O2'
  lca[*].ion_state = 1
  ;; 0 = original version
  ;; lca[*].version = version
  for ilc=long(0), nlines-1 do begin
     w = lc_edlen(o2.wavenum[ilc])
     lca[ilc].wavelen = w
     lca[ilc].ptype = !lc.wavelen
     lca[ilc].value = w
     ;; Errors in Naus are 0.01 1/cm
     lca[ilc].error = lc_edlen(o2.wavenum[ilc] - 0.01) - w
     lca[ilc].limits = [w - err2lim*lca[ilc].error, $
                        w + err2lim*lca[ilc].error]
  endfor
  
  sidx = lc_sort(lca, /mark_dup)
  
  lca = lc_clean_dup(lca, sidx)
  ;; Put a copy of the catalog on the heap in list pointed to by
  ;; !lc.cats so we don't have to read it in next time
  tmp = {cat	: lca, $
         next: !lc.cats}
  !lc.cats = ptr_new(tmp, /allocate_heap, /no_copy)

  ;; Recursively call ourselves to use the wavelength range code
  return, lc_read_huestis(wrange=wrange)

end
