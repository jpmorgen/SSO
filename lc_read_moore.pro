; +
;; $Id: lc_read_moore.pro,v 1.2 2015/03/03 20:06:44 jpmorgen Exp $

;; lc_read_moore 
;;
;; Charlotte Emma Moore, M.G.J. Minnaert, and J. Houtgast "The solar
;; spectrum 2935 A to 8770 A; second revision of Rowland's Preliminary
;; table of solar spectrum wavelengths" Washington, National Bureau of
;; Standards, 1966.  This is the most encyclopedic source of
;; atmospheric and solar lines I know about.  The wavelengths,
;; however, are not quite right.

;; Read values from the above catalog into lc_struct records.
;; wavelen = wavelength in Angtroms (A)
;; ew = equivalent width in mA
;; T1 = A letter whose meaning I don't understand
;; T2 = occcationally an asterisk.  Again, I don't understand its meaning
;; rw = reduced width (delta lambda/lambda) (F) [whatever that is]
;; Spot = ?
;; EProt = Lower excitation potential or Rotaional line
;; RMTvib = RMT number of vibrational band


; -

function lc_read_moore, wrange=wrange

  init = {lc_sysvar}

  ;; Check to see if we have read the ASCII file once already in this
  ;; session.
  tmp = lc_read_check(!lc.moore) 
  if ptr_valid(tmp) then begin
     if N_elements(wrange) eq 0 then $
       return, (*tmp).cat

     good_idx = where(wrange[0] le (*tmp).cat.wavelen and $
                      (*tmp).cat.wavelen le wrange[1], count)
     if count eq 0 then $
       message, 'ERROR: no entries found in wavelength range'
     
     return, (*tmp).cat[good_idx]
  endif

  template $
    = { VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''				, $
        FIELDCOUNT      :		  8		, $
        FIELDTYPES      :   [5,7,7,4,4,7,7,7,7,7]	, $
        FIELDNAMES      :   ['wavelen', 'T1', 'T2', 'ew', 'rw', 'spot', 'id', 'EProt','RMTvib','notes'],$
        FIELDLOCATIONS  :   [0,9,10,14,19,26,35,47,53,58]	, $
        FIELDGROUPS     :   [0,1, 2, 3, 4, 5, 6, 7, 8, 9]}
  
  cd, !lc.top + '/sun/ftp.noao.edu'
  message, /INFORMATIONAL, 'NOTE: reading ASCII table, expect delay'
  
  moore = read_ascii('Moore', template=template)
  
  ;; Make an lc array with two elements per Moore catalog entry: one
  ;; for the wavelength and one for the equivalent width
  nlines = N_elements(moore.wavelen)
  lca = replicate(!lc.lc_struct, nlines * 2)
  lca[*].cat = !lc.moore
  ;; 0 = original version
  ;; lca[*].version = version

  for im=long(0), nlines-1 do begin
     ilc = im * 2
     src = !eph.sun
     id = moore.id[im]
     atmpos = strpos(id, 'ATM') 
     if atmpos ne -1 then begin
        src = !eph.earth
        id = strmid(id, atmpos+3)
     endif
     lca[ilc:ilc+1].src = src
     w = moore.wavelen[im]
     lca[ilc:ilc+1].wavelen = w
     ;; Dump the whole Moore ID in as the name
     lca[ilc:ilc+1].name = moore.id[im]
     species = strsplit(id, '[ -(/)]', /extract, /regex)
     lca[ilc:ilc+1].species = species[0]
     ;; Don't worry about mweight for now.  If incorporated into
     ;; solarsoft, can use CHIANTI stuff for this
     ;; Don't worry about ionization stuff either
     ;; ltype is possible, if I interpret Moore's markings
     lca[ilc].ptype = !lc.wavelen
     lca[ilc].value = w
     ;; This is probably a little too big, but helps get other
     ;; catalogs ranked higher
     lca[ilc].error = 0.020
     ;; These should be generous enough to be valid no matter what
     lca[ilc].limits = [w - 0.015, w + 0.015]
     lca[ilc].quality = !lc.OK
     lca[ilc+1].ptype = !lc.ew
     lca[ilc+1].value = -moore.ew[im]
     lca[ilc+1].quality = !lc.good
     ;; Don't let lines become positive or too large
     lca[ilc+1].limits[1] = lca[ilc+1].value / 3.
     lca[ilc+1].limits[0] = lca[ilc+1].value * 10.
  endfor

  sidx = lc_sort(lca, /mark_dup)

  lca = lc_clean_dup(lca, sidx)
  ;; Put a copy of the catalog on the heap in list pointed to by
  ;; !lc.cats so we don't have to read it in next time
  tmp = {cat	: lca, $
         next: !lc.cats}
  !lc.cats = ptr_new(tmp, /allocate_heap, /no_copy)

  ;; Recursively call ourselves to use the wavelength range code
  return, lc_read_moore(wrange=wrange)

end
