; +
;; $Id: lc_read_kurucz.pro,v 1.1 2015/03/03 20:06:17 jpmorgen Exp $

;; lc_read_kurucz 
;;

; -

function lc_read_kurucz, wrange=wrange, noreread=noreread
;+
; NAME:
;
;
;
; PURPOSE:
;
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:  
;
;   Common blocks are ugly.  Consider using package-specific system
;   variables.
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
; $Id: lc_read_kurucz.pro,v 1.1 2015/03/03 20:06:17 jpmorgen Exp $
;-

  init = {lc_sysvar}

  ;; Check to see if we have read the ASCII file once already in this
  ;; session.
  tmp = lc_read_check(!lc.kurucz) 
  if ptr_valid(tmp) then begin
     if N_elements(wrange) eq 0 then $
       return, (*tmp).cat
     
     ;; check wavelength range.  Add on some extra range, just in case
     ;; we don't have wavelength values precisely at the boundaries.
     ;; Hmm.  That does not always work.  Just set noreread so we
     ;; don't infinite loop
     lca = (*tmp).cat
     delta = median(lca[1:N_elements(lca)-2].wavelen - lca[0:N_elements(lca)-1].wavelen)
     if keyword_set(noreread) or $
       (wrange[0] ge min(lca.wavelen)-10*delta and wrange[1] le max(lca.wavelen)+10*delta) then begin
        good_idx = where(wrange[0] le lca.wavelen and $
                         lca.wavelen le wrange[1], count)
        if count eq 0 then $
          message, 'ERROR: no entries found in wavelength range'
        
        return, lca[good_idx]

     endif
     noreread = 1

  endif

  ;; Read file(s)

  template $
    = { VERSION         :            1.00000            , $
        DATASTART       :                 0             , $
        DELIMITER       :         ''                    , $
        MISSINGVALUE    :                !values.f_nan  , $
        COMMENTSYMBOL   :   ''                          , $
        FIELDCOUNT      :                30             , $
        FIELDNAMES      :   ['wavelen', 'loggf', 'nelement', 'E0', 'J0', 'L0', 'E1', 'J1', 'L1', 'grad', 'gstark', 'gvdW', 'ref', 'nLTE0', 'nLTE1', 'ISO', 'loghyper', 'ISO2', 'logISOf', 'dEf0', 'dEf1', 'f0', 'f0note', 'f1', 'f1note', 'N1', 'C1', 'glande0', 'glande1', 'iso_dwave'], $
        FIELDTYPES      :   [5, 5, 5, 5, 5, 7, 5, 5, 7, 5, 5, 5, 7,  2,  2,  2,  5,  2,  5,  2,  2,  2,  7,  2,  7,  2,  7,  2,  2,  2], $
        FIELDLOCATIONS  :   [0,11,18,24,36,42,52,64,70,80,86,92,98,102,104,106,109,115,118,124,129,135,136,138,139,140,141,143,148,153], $
        FIELDGROUPS     :   [0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]}
  
  cd, !lc.top + '/sun/kurucz/lines'
  
  ;; Upper limit of Kurucz files.  He uses nm, I use A.  Lowest is
  ;; 2.4898 nm, highest is 54956.4080 nm
  up_lim = [2.4898, 100, 150, 200, 300, 400, 500, 600, 800, 1200, 3000, 100000] * 10

  ;; This is a huge wavelength range + a lot of data.  Hopefully the
  ;; user will specify a smaller range
  if N_elements(wrange) ne 2 then $
    wrange = [min(up_lim), max(up_lim)]

  if wrange[0] gt wrange[1] then $
    message, 'ERROR: wrange[0] must be less than or equal to wrange[1]'

  ;; Pick out files to read
  read_idx = where(wrange[0] lt up_lim[1:N_elements(up_lim)-1] and $
                   up_lim[0:N_elements(up_lim)-2] lt wrange[1] , count) + 1
  if count eq 0 then $
    message, 'ERROR: no data in wavelength range'

  ;; Get ready to build up line list from individual files
  lca = !values.d_nan
  for iridx=0, N_elements(read_idx)-1 do begin
     ;; Convert upper limits to filenames (which are in 0-prepended nm)
     ul = up_lim[read_idx[iridx]]/10.
     sul = strtrim(fix(ul),2)
     if ul lt 1000 then $
       sul = '0' + sul
     fname = string('gf' + sul + '.100')
     ;; Last set of lines in in gfend.100
     if ul gt 3000 then $
       fname = 'gfend.100'
     message, /INFORMATIONAL, 'NOTE: reading ASCII table ' + fname + ', expect delay'
     kt = read_ascii(fname, template=template)

     ;; Kurucz calculates the wavelengths in an inertial,
     ;; non-gravitational frame.  The wavelengths need to be corrected
     ;; for gravitational redshift for detection on earth.  To be truly
     ;; general and precise, I would leave the gravitational redshift
     ;; calculation for later, when the path is know.  However, I think
     ;; bounces don't effect the detected wavelengths, just the position
     ;; of the receiving body relative in the originating body's
     ;; gravitational field.
     ;; http://www.astro.lu.se/~dainis/HTML/GRAVITAT.html gives a simple
     ;; explanation.  Use 633 m/s for interception at earth.  Difference
     ;; between that and 636.1 m/s at infinity is 0.065 mA, which is
     ;; safely negligible.  In spite of this adjustment, Kurucz
     ;; wavelengths come out 6-8 mA low compared to Allende-Preito.  This
     ;; might be because of the solar radius at which the lines are
     ;; actually produced.
     dw = 633d/!lc.c * kt.wavelen
     kt.wavelen = kt.wavelen + dw; - 8

     ;; Make an lc array with just one element per Kurucz catalog entry
     ;; since we are taking the equivalent widths from the other catalogs
     nlines = N_elements(kt.wavelen)
     lct = replicate(!lc.lc_struct, nlines)
     lct[*].cat = !lc.kurucz
     ;; 0 = original version
     ;; lct[*].version = version

     lct.src = !eph.sun
     lct.wavelen = kt.wavelen*10d
     lct.species = !lc.asymbols[fix(kt.nelement)]
     lct.mweight = !lc.amasses[fix(kt.nelement)]
     lct.ion_state = kt.nelement - fix(kt.nelement)
     lct.name = lct.species + strtrim(lct.ion_state + 1, 2)
     lct.ptype = !lc.wavelen
     lct.value = lct.wavelen
     ;; Kurucz does not provide errors directly.  Estimate at 4 mA and
     ;; clamp down on the limits
     lct.error = 0.004
     lct.limits[0] = lct.value - lct.error
     lct.limits[1] = lct.value + lct.error
     lct.quality = !lc.best
     lct.path = [!eph.sun, !eph.earth]

     lca = array_append(lct, lca)

  endfor ;; Each Kurucz file

  sidx = lc_sort(lca, /mark_dup)

  lca = lc_clean_dup(lca, sidx)
  ;; Put a copy of the catalog on the heap in list pointed to by
  ;; !lc.cats so we don't have to read it in next time
  tmp = {cat	: lca, $
         next: !lc.cats}
  !lc.cats = ptr_new(tmp, /allocate_heap, /no_copy)

  ;; Recursively call ourselves to use the wavelength range code
  return, lc_read_kurucz(wrange=wrange, noreread=noreread)

end
