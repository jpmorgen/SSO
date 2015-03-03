; +
;; $Id: lc_read_hitran.pro,v 1.1 2015/03/03 20:07:21 jpmorgen Exp $

;; lc_read_hitran 

;; Reads 100 column format HITRAN .out files into the lc structure.
;; The .out files should be generated for the wavelength range of
;; interest by the JAVAHawks application, which searches all the
;; HITRAN database files.  See
;;
;; http://cfa-www.harvard.edu/hitran
;;
;; err2lim is the factor to multiply error bars by to get parameter
;; limits.  Default=3
;;
;; RETURNS WIDTHS IN MILLIANGSTROMS

; -

function lc_read_hitran, err2lim=err2lim, wrange=wrange

  init = {lc_sysvar}

  ;; Check to see if we have read the ASCII file once already in this
  ;; session.
  tmp = lc_read_check(!lc.hitran) 
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

  ;; nu = wavenumber in 1/cm
  ;; s = intensity in cm^-1/(molecule*cm^-2) @296

  template $
    = { VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''				, $
        FIELDCOUNT      :		  20		, $
        FIELDTYPES      :   [2,2,5, 5, 5, 4, 4, 5, 5, 5, 2, 2, 7, 7, 1, 1, 1, 2, 2, 2], $
        FIELDNAMES      :   ['mol', 'iso', 'nu', 's', 'r', 'hwhma', 'hwhms', 'e','n','delta','ivp', 'ivpp','qp','qpp','ierrnu','ierrs','ierrwa','irefnu','irefs','irefwa'],$
        FIELDLOCATIONS  :   [0,2,3,16,26,35,40,45,55,59,68,71,74,84,91,92,93,94,96,98], $
        FIELDGROUPS     :   [0,1,2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19]}
  
  ;; For translating HITRAN molecule numbers
  mol = ['NONE', 'H2O', 'CO2', 'O3', 'N2O', 'CO', 'CH4', 'O2', 'NO', $
         'SO2', 'NO2', 'NH3', 'HNO3', 'OH', 'HF', 'HCl', 'HBr', 'HI', $
         'ClO', 'OCS', 'H2CO', 'HOCl', 'N2', 'HCN', 'CH3Cl', 'H2O2', $
         'C2H2', 'C2H6', 'PH3', 'COF2', 'SF6', 'H2S', 'HCOOH', 'HO2', $
         'O', 'ClONO2', 'NO+', 'HOBr', 'C2H4']


  ;; from http://www.pa.op.dlr.de/LIDAR/WIND/ALIENS/Docu/Appen2.pdf 
  ;; which went up to HCOOH.  Calculated my own from a periodic table
  mweight = [0, 18.01, 44.01, 48.00, 44.01, 28.01, 16.04, 32.00, 30.01, $
             64.06, 46.01, 17.03, 63.01, 17.01, 20.01, 36.46, 80.91, 127.91, $
             51.45, 60.07, 30.03, 52.46, 28.01, 27.03, 50.49, 34.01, $
             26.04, 30.07, 33.99, 66.01, 146.05, 34.08, 46.03, 33.0067, $
             15.9994, 97.4579, 30.0061, 96.9113, 28.0536]

  ;; Default fraction is 1E-6, since minor constituent fractions are
  ;; model dependant
  mol_frac = make_array(N_elements(mol), value = 1D-6)
  ;; Assign standard textbook values from
  ;; http://www-as.harvard.edu/people/faculty/djj/book/bookchap1.html#pgfId=439437
  mol_frac[22]	= 0.7808d ;; N2
  mol_frac[7]	= 0.2095d ;; O2
  mol_frac[2]	= 365d-6  ;; CO2
  mol_frac[3]	= 1d-6    ;; O3
  mol_frac[6]	= 1.7d-6  ;; CH4
  mol_frac[4]	= 320d-9  ;; N2O
  
  
  ;; I had to get the error definitions from the web:
  ;; http://cfa-www.harvard.edu/hitran/facts.html Wavenumber errors
  ;; are just 10^-ierr.  Widths and others are really ranges.  For
  ;; 0.2 and below, I have used either the upper edge of the range
  ierrt = [!values.d_nan, 0, 1, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01]

  cd, !lc.top + '/HITRAN'
  message, /INFORMATIONAL, 'NOTE: reading ASCII table, expect delay'
  hitran = read_ascii('HITRAN_optical.out', template=template)
  
  ;; Make an lc array with three elements per HITRAN catalog entry:
  ;; wavelength, equiv width, and (Gaussian) FWHM, so that is 3
  ;; parameters
  nparams = 3
  nlines = N_elements(hitran.nu)
  lca = replicate(!lc.lc_struct, nlines * 3)
  lca[*].cat = !lc.hitran
  lca[*].src = !eph.earth
  ;; Most of the HITRAN species are neutral (corrected below)
  lca[*].ion_state = 1
  ;; 0 = original version
  ;; lca[*].version = version

  for ih=long(0), nlines-1 do begin
     ilc = ih * nparams
     w = lc_edlen(hitran.nu[ih], /noreverse)
     lca[ilc:ilc+2].wavelen = w
     lca[ilc:ilc+2].species = mol[hitran.mol[ih]]
     ;; Include ISO, iv and q stuff in name just for the heck of it.
     lca[ilc:ilc+2].name = lca[ilc].species + $
       ' I'  + strtrim(hitran.iso[ih], 2) + $
       ' iv' + strtrim(hitran.ivp[ih], 2) + $
       ' q'  + hitran.qp[ih] + $
       ' '   + hitran.qpp[ih]
     ;; --> HERE IS WHERE I MESS WITH THE WAVELENGTH ERRORS.
     ;; ierr = 0 means no error provided.  This is inconvenient, since
     ;; the measurements are probably fine + I need the lines to be
     ;; constrained.  Put a marker in the name + assign an error index
     ;; of 2
     if hitran.ierrnu[ih] eq 0 then begin
        lca[ilc:ilc+2].name = 'badw ' + lca[ilc].name
        hitran.ierrnu[ih] = 6
     endif
     
     ;; Check for the ionization state
     temp = lca[ilc].species
     plus = strpos(temp, '+', /reverse_offset) 
     while plus ne -1 do begin
        lca[ilc:ilc+2].ion_state = lca[ilc:ilc+2].ion_state + 1
        temp = strmid(temp, 0, plus)
        plus = strpos(temp, '+', /reverse_offset) 
     endwhile
     ;; Molecular weight
     lca[ilc:ilc+2].mweight = mweight[hitran.mol[ih]]

     lca[ilc].ptype = !lc.wavelen
     lca[ilc].value = w
     ;; All HITRAN wavelengths should be the best quality
     lca[ilc].quality = !lc.best
     ;; Use the wavenumber error index
     nuerr = 10d^(-1d * double(hitran.ierrnu[ih]))
     lca[ilc].error = lc_edlen(hitran.nu[ih] - nuerr) - w
     ;; Use 3 sigma as reasonably tight limits
     lca[ilc].limits = [w - err2lim*lca[ilc].error, $
                        w + err2lim*lca[ilc].error]
     
     ;; Estimate equivalent width assuming a plane-parallel atmosphere
     ;; at a uniform temperature.  First calculate the transmission.
     lca[ilc+1].ptype = !lc.ew
     lca[ilc+1].value = $
       exp(-hitran.s[ih] / hitran.nu[ih] * $
           mol_frac[hitran.mol[ih]] * mweight[hitran.mol[ih]] * $
           !lc.NRTog * !lc.NA)
     ;; Give ourselves a large range of transmissions, but we can't
     ;; get more than 1
     lca[ilc+1].limits = [lca[ilc+1].value / 10, min([lca[ilc+1].value * 100, 1])]

     ;; Assume the air half width is the Gaussian part.  CONVERT TO MILLIANGSTROMS
     lca[ilc+2].ptype = !lc.gwidth
     lca[ilc+2].value = 2*(lc_edlen(hitran.nu[ih] - hitran.hwhma[ih]) - w) * 1000d
     lca[ilc+2].quality = !lc.OK ;; I am not sure about this
     lca[ilc+2].limits = [0, err2lim*lca[ilc+2].error] * 1000d

     ;; now go back and calculate the equivalent width, noting that
     ;; the sense of the limits is reversed
     lca[ilc+1].value = - (1d - lca[ilc+1].value) * lca[ilc+2].value
     lca[ilc+1].quality = !lc.bad
     for ilim=0,1 do begin
        lca[ilc+1].limits[ilim] = - (1d - lca[ilc+1].limits[ilim]) * lca[ilc+2].value
     endfor
     lca[ilc+1].limits = transpose(lca[ilc+1].limits)
     lca[ilc+1].error = - lca[ilc+1].value * ierrt[hitran.ierrs[ih]]

  endfor
  
  sidx = lc_sort(lca, /mark_dup)
  
  lca = lc_clean_dup(lca, sidx)
  ;; Put a copy of the catalog on the heap in list pointed to by
  ;; !lc.cats so we don't have to read it in next time
  tmp = {cat	: lca, $
         next: !lc.cats}
  !lc.cats = ptr_new(tmp, /allocate_heap, /no_copy)

  ;; Recursively call ourselves to use the wavelength range code
  return, lc_read_hitran(wrange=wrange)

end
