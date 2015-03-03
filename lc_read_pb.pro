; +
;; $Id: lc_read_pb.pro,v 1.2 2015/03/03 20:05:55 jpmorgen Exp $

;; lc_read_pb
;;
;; A. Keith Pierce and James B. Brekenridge, "The Kitt Peak table of
;; photographic solar spectrum wavelengths" Tucson Arizona, KPNO,
;; 1973.  This has slightly better wavelenghts than Moore, but not as
;; many lines.  It is a little more machine friendly.

;; Read values from the above catalog into lc_struct records.
;; wavelen = wavelength in Angtroms (A)
;; source = S:solar, T:terrestrial
;; N1 = number whose meaning I do not know
;; wavenum = vacuum wavenumber
;; N2 = number whose meaning I do not know
;; N3 = number whose meaning I do not know
;; L1 = letter whose meaning I do not know
;; N4 = number whose meaning I do not know
;; id = species identification
;; multiplet = multiplet number (I think these correspond to Moore's RMTvib)


; -

function lc_read_pb, wrange=wrange

  init = {lc_sysvar}

  ;; Check to see if we have read the ASCII file once already in this
  ;; session.
  tmp = lc_read_check(!lc.pb) 
  if ptr_valid(tmp) then begin
     if N_elements(wrange) eq 0 then $
       return, (*tmp).cat

     good_idx = where(wrange[0] le (*tmp).cat.wavelen and $
                      (*tmp).cat.wavelen le wrange[1], count)
     if count eq 0 then $
       message, 'ERROR: no entries found in wavelength range'
     
     return, (*tmp).cat[good_idx]
  endif

  template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''				, $
        FIELDCOUNT      :		  10		, $
        FIELDTYPES      :   [5,7,5,4,4,7,4,7,7,7]	, $
        FIELDNAMES      :   ['wavelen', 'source', 'N1', 'wavenum', 'N2', 'N3', 'L1', 'N4', 'id', 'multiplet'],$
        FIELDLOCATIONS  :   [0,9,10,13,24,28,35,38,44,52]	, $
        FIELDGROUPS     :   [0,1, 2, 3, 4, 5, 6, 7, 8, 9]}

  cd, !lc.top + '/sun/ftp.noao.edu'
  message, /INFORMATIONAL, 'NOTE: reading ASCII table, expect delay'

  pb = read_ascii('Pierce_Brekenridge', template=template)

  nlines = N_elements(pb.wavelen)
  lca = replicate(!lc.lc_struct, nlines)
  lca[*].cat = !lc.pb
  ;; 0 = original version
  ;; lca[*].version = version

  for ilc=long(0), nlines-1 do begin
     case pb.source[ilc] of
        'S'	:	lca[ilc].src = !eph.sun
        'T'	:	lca[ilc].src = !eph.earth
        else	:	message, 'ERROR: unrecognized source'
     endcase
     lca[ilc].wavelen = pb.wavelen[ilc]
     lca[ilc].quality = !lc.good
     ;; Handle serial below
     ;; Dump the whole Pb ID in as the name
     id = pb.id[ilc]
     lca[ilc].name = id
     atmpos = strpos(id, 'ATM') 
     if atmpos ne -1 then $
        id = strmid(id, atmpos+3)

     species = strsplit(id, '[ -(/)]', /extract, /regex)
     lca[ilc].species = species[0]
     ;; Don't worry about mweight for now.  If incorporated into
     ;; solarsoft, can use CHIANTI stuff for this
     ;; Don't worry about ionization stuff either
     ;; ltype is possible, if I interpret their markings
     lca[ilc].ptype = !lc.wavelen
     lca[ilc].value = pb.wavelen[ilc]
     ;; Estimate errors, since I don't know what the columns really mean
     lca[ilc].error = 0.006
     lca[ilc].limits = [pb.wavelen[ilc] - 0.010, pb.wavelen[ilc] + 0.010]
  endfor

  sidx = lc_sort(lca);, /mark_dup)
  
  lca = lc_clean_dup(lca, sidx)

  ;; Put a copy of the catalog on the heap in list pointed to by
  ;; !lc.cats so we don't have to read it in next time
  tmp = {cat	: lca, $
         next: !lc.cats}
  !lc.cats = ptr_new(tmp, /allocate_heap, /no_copy)

  ;; Recursively call ourselves to use the wavelength range code
  return, lc_read_pb(wrange=wrange)

end
