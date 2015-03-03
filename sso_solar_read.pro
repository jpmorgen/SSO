; +
;; $Id: sso_solar_read.pro,v 1.1 2015/03/03 20:16:27 jpmorgen Exp $

;; Read in all the solar and atmospheric atlases I know about to
;; generate a high quality linelist in ssg param/parinfo format.

; -

pro sso_solar_read, params, parinfo

  ;; Using the strong lines, I measured this systematic shift in
  ;; Allende Prieto - Meylan and the width of the Gaussian fit to a
  ;; histrgram of the distribution
  meylan_shift = 0.00474406 ; This works out to be 0.22 km/s at [OI]
  ap_vs_m_width = 0.00569594
  ap_mean_error = 0.0042552749

  ;; Correct for whatever systematic problem Meylan had in the
  ;; absolute wavelength reference
  if NOT keyword_set(center) then center = meylan_shift
  ;; But be more liberal with the wavelength matching.  This 
  if NOT keyword_set(width) then width = ap_mean_error*4

  verbose = 1
  if keyword_set(silent) then verbose=0
  
  ;; Charlotte Emma Moore, M.G.J. Minnaert, and J. Houtgast "The solar
  ;; spectrum 2935 A to 8770 A; second revision of Rowland's
  ;; Preliminary table of solar spectrum wavelengths" Washington,
  ;; National Bureau of Standards, 1966.  This is the most
  ;; encyclopedic source of atmospheric and solar lines I know about.
  ;; The wavelengths, however, are not quite right.

  ;; Trying to guess from the multiplet table Ken Carpenter had about
  ;; what the columns mean.  EP is lower state excitation potential
  moore_template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''				, $
        FIELDCOUNT      :		  8		, $
        FIELDTYPES      :   [5,7,7,4,4,7,7,7,7,7]	, $
        FIELDNAMES      :   ['wavelen', 'T1', 'T2', 'N1', 'N2', 'T3', 'id', 'EP','multiplet','T4'],$
        FIELDLOCATIONS  :   [0,9,10,14,19,26,35,47,53,58]	, $
        FIELDGROUPS     :   [0,1, 2, 3, 4, 5, 6, 7, 8, 9]}
  
  ;; A. Keith Pierce and James B. Brekenridge, "The Kitt Peak table of
  ;; photographic solar spectrum wavelengths" Tucson Arizona, KPNO,
  ;; 1973.  This has slightly better wavelenghts but not as many lines.
  pb_template = $
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

  ;; A catalogue of accurate wavelengths in the optical spectrum of the Sun
  ;;     Allende Prieto C., Garcia Lopez R.J.
  ;;    <Astron. Astrophys. Suppl. Ser. 131, 431 (1998)>
  ;;    =1998A&AS..131..431A      (SIMBAD/NED BibCode)
  ;;
  ;; These are fits to the peaks of the lines in Kurucz's solar
  ;; spectra.  Presumably the wavelengths are the best available as
  ;; of 1998.

  ap_template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''				, $
        FIELDCOUNT      :		  7		, $
        FIELDTYPES      :   [5,5,5,5,7,4,4]		, $
        FIELDNAMES      :   ['lambdaD', 'e_lambdaD', 'lambdaF', 'e_lambdaF', 'Ion', 'EP', 'loggf'], $
        FIELDLOCATIONS  :   [0,10,17,27,34,38,43]	, $
        FIELDGROUPS     :   [0, 1, 2, 3, 4, 5, 6]}

  ;; These are very accurate O2 molecular transition wavenumbers as
  ;; provided by David Huestis.  His notes say "See Naus et al
  ;; Spectrochimica Acta A 55, 1255 (1999) for positions" which might
  ;; mean that is the reference.
  o2_egamma_template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  2 		, $
        DELIMITER       :	  ''	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   ''				, $
        FIELDCOUNT      :		  4		, $
        FIELDTYPES      :   [5,5,4,7]			, $
        FIELDNAMES      :   ['wavenum', 'T1', 'T2', 'T3'],$
        FIELDLOCATIONS  :   [3,15,27,33]		, $
        FIELDGROUPS     :   [0, 1, 2, 3]}
  
  ;; Thomas Meylan Thesis, Chapter 7, which was also condensed into an
  ;; ApJS paper has equivalent widths for some of the stronger solar
  ;; lines.  He fit some that had uncertain IDs and also some of the
  ;; weaker features.  The weaker features were put into a separate
  ;; table.

;@ARTICLE{1990PhDT........84M,
;    author = {{Meylan}, T.~R.},
;    title = "{A Chemical Abundance Survey of Solar Neighborhood, Solar-Like Stars.}",
;    journal = {Ph.D.~Thesis},
;    year = 1990,
;    adsurl = {http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode=1990PhDT........84M&amp;db_key=AST},
;    adsnote = {Provided by the NASA Astrophysics Data System}
;}

;@ARTICLE{1993ApJS...85..163M,
;    author = {{Meylan}, T. and {Furenlid}, I. and {Wiggs}, M.~S. and {Kurucz}, R.~L.
;        },
;    title = "{A critical list of Voigt-fitted equivalent width measurements based on the solar flux spectrum}",
;    journal = {\apjs},
;    year = 1993,
;    month = mar,
;    volume = 85,
;    pages = {163-180},
;    adsurl = {http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode=1993ApJS...85..163M&amp;db_key=AST},
;    adsnote = {Provided by the NASA Astrophysics Data System}
;}
;
;

  meylan_template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  '&'	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   '{'			, $
        FIELDCOUNT      :		  7		, $
        FIELDTYPES      :   [5,5,5,5,5,7,7]	, $
        FIELDNAMES      :   ['wavelen', 'loggfp', 'loggf79', 'loggf90', 'ew', 'junk1', 'junk2'],$
        FIELDLOCATIONS  :   [0,10,20,30,40,49,50]	, $
        FIELDGROUPS     :   [0,1,2,3,4,5,6]}
  meylan_weak_template = $
    {   VERSION         :	     1.00000		, $
        DATASTART       :		  0 		, $
        DELIMITER       :	  '&'	    		, $
        MISSINGVALUE    :		 !values.f_nan	, $
        COMMENTSYMBOL   :   '{'			, $
        FIELDCOUNT      :		  4		, $
        FIELDTYPES      :   [7,5,5,5]	, $
        FIELDNAMES      :   ['species', 'wavelen', 'ew', 'loggf'],$
        FIELDLOCATIONS  :   [0,7,19,28]	, $
        FIELDGROUPS     :   [0,1,2,3]}


  cd, '/home/jpmorgen/data/solar_atlas/'

  ;; Start out by reading in Moore's table, which, along with Pierce
  ;; and Brekenridge's results, I downloaded from ftp.noao.edu
  cd, 'ftp.noao.edu'

  ;; Note that the Fe 1P multiplet 921, near 6396 A, has a funky
  ;; wavelength, presumably because it is blended
  moore = read_ascii('Moore', template=moore_template)
  pb    = read_ascii('Pierce_Brekenridge', template=pb_template)
  ap    = read_ascii('../allende_prieto/table1.dat', template=ap_template)

  npb = N_elements(pb.wavelen)
  pb_wavelen = pb.wavelen[0:npb-2]
  next_pb_wavelen = pb.wavelen[1:npb-1]
  pb_match_idx = longarr(npb)
  nap = N_elements(ap.wavelen)
  ap_wavelen = ap.wavelen[0:nap-2]
  next_ap_wavelen = ap.wavelen[1:nap-1]
  ap_match_idx = longarr(nap)

  ;; For each entry in the longest table (Moore)
  for midx=0,N_elements(moore.wavelen)-1 do begin
     best_wavelen = moore.wavelen[midx]
     ;; Skip the bogus -3 entry
     if best_wavelen gt 0 then begin
        ;; For now assume all Moore's lines are fittable with Voigts
        tparinfo = sso_init_voigt(best_wavelen)
        

        ;; Add to any existing parinfo structure.  Set parinfo=0 to
        ;; reinitialize

     ;; Look through Pierce and Brekenridge table, which should be
     ;; close and includes terrestrial lines
     pb_match_idx = -1
     close_pb_idx = where(pb_wavelen le best_wavelen and $
                          best_wavelen lt next_pb_wavelen, $
                          pb_count)
     if pb_count ne 0 then begin
        pb_match_idx = close_idx[0]
        if best_wavelen - pb_wavelen[close_idx[0]] gt $
          next_pb_wavelen[close_idx[0]] - best_wavelen then $
          pb_match_idx = close_idx[0]+1
        ;; Check for bad match
        if abs(pb_wavelen[pb_match_idx] - moore.wavelen[midx]) $
          gt width then $
          pb_match_idx = -1
     endif

     if pb_match_idx eq -1 then begin
        ;; We have to figure out from Moore's semi-standardized
        ;; notation if a line is atmospheric or not.
        if strpos(moore.id, 'ATM') eq -1 then begin
           ;; We are either a poorly labeled atmospheric line or not
           ;; an atmospheric line.
           
        endif
        
     endif else begin
        best_wavelen = pb.wavelen[pb_match_idx]
     endelse

     

  endfor ;; Loop over Moore entries

stop

  type = strlowcase(type)
  case type of 
     'strong' : meylan = read_ascii('equiv_widths_strong.txt', template=meylan_template)
     'uncertain' : meylan = read_ascii('equiv_widths_IDq.txt', template=meylan_template)
     'weak' : meylan = read_ascii('equiv_widths_weak.txt', template=meylan_weak_template)
     else : message, 'ERROR: ' + string(type) + ' unrecognized, expecting strong, uncertain, or weak'
  endcase

  if NOT keyword_set(noshift) then meylan.wavelen = meylan.wavelen + center

  solar_atlas=read_ascii('/home/jpmorgen/data/solar_atlas/allende_prieto/table1.dat', $
                         template=allende_prieto_template)

  wavelen = solar_atlas.lambdaF[0:N_elements(solar_atlas.lambdaF)-2]
  next_wavelen = solar_atlas.lambdaF[1:N_elements(solar_atlas.lambdaF)-1]
  ;; Use negative values to signal unmatched Meylan lines
  new_mwavelen = -meylan.wavelen

  ;; For each entry in the Meylan table
  sort_idx = sort(meylan.wavelen)
  for sidx=0,N_elements(meylan.wavelen)-1 do begin
     midx = sort_idx[sidx]
     close_idx = where(wavelen le meylan.wavelen[midx] and $
                       meylan.wavelen[midx] lt next_wavelen, $
                       count)
     if count le 0 then begin
        if keyword_set(verbose) then $
        message, 'WARNING: wavelength out of range' + string(meylan.wavelen[midx]), /continue
     endif else begin
        if count gt 1 and keyword_set(verbose) then $
          message, 'WARNING: duplicate entries in Allende-Prieto table near '+ string(wavelen[close_idx[0]]), /continue
        
        new_mwavelen[midx] = wavelen[close_idx[0]]
        if meylan.wavelen[midx] - wavelen[close_idx[0]] gt $
          next_wavelen[close_idx[0]] - meylan.wavelen[midx] then begin
           new_mwavelen[midx] = next_wavelen[close_idx[0]]
        endif
        if abs(new_mwavelen[midx] - meylan.wavelen[midx]) $
          gt width then begin
           new_mwavelen[midx] = -meylan.wavelen[midx]
           if keyword_set(verbose) then $
             message, /continue, 'WARNING: gap of ' + string(next_wavelen[close_idx[0]] - wavelen[close_idx[0]]) + ' A in Allende Prieto at Meylan wavelength of ' + string(meylan.wavelen[midx])
        endif
     endelse ;; Wavelength covered by Allende Prieto
  endfor ;; Meylan loop

  ;; Save the flagged list of matched and unmatched lines to the
  ;; output variable and set all the wavelengths back to positive for
  ;; plotting
  matched_waves = new_mwavelen
  new_mwavelen = abs(new_mwavelen)

  ;; Make a variable with the differences between the Allende Prieto
  ;; and Meylan wavelengths.  Those with no matches inside of "width"
  ;; will be 0.
  diffs = new_mwavelen[sort_idx] - meylan.wavelen[sort_idx]
  good_idx = where(diffs ne 0, count)
  if keyword_set(plot) and count gt 0 then begin
     window,2
     sort_idx = sort(new_mwavelen)
     binsize = 0.001
     hist_range = 0.1
     diff_hist = histogram(diffs, binsize=binsize, $
                           min=-hist_range, max=hist_range)
     xaxis = lindgen(N_elements(diff_hist))*binsize-hist_range
     plot, xaxis, diff_hist, psym=3, $
           title='Histrogram of wavelength differences', $
           xtitle='Allende Prieto - Meylan (A)'
     oploterr, xaxis, diff_hist, sqrt(diff_hist), 3
     
     peak_idx = where(diff_hist eq max(diff_hist, /NAN))
     to_fit = diff_hist
     to_fit[peak_idx] = mean(diff_hist)
     yfit = gaussfit(xaxis, to_fit, NTERMS=3, params)
     print, '     amplitude  center       1/e width'
     print, params
     oplot, xaxis, yfit
     print, 'Mean Allende Prieto error: ', mean(solar_atlas.e_lambdaF)

     window,3
     title = string(format='(a, " Meylan vs Allende Prieto, cutoff=", f6.3)', $
                    type, width)
     plot, new_mwavelen[sort_idx], diffs, title=title, $
           psym=3, xtitle='Wavelength (A)', ytitle='Wavelength Difference (A)'
     oploterr, new_mwavelen[sort_idx], diffs, solar_atlas.e_lambdaF, 3
  endif else begin ;; plot
     if count eq 0 then $
       message, /CONTINUE, 'NOTE: no matches found, so not plotting.'
  endelse

  if keyword_set(sort) then begin
     sort_idx = sort(new_mwavelen)
     meylan.wavelen[*] = meylan.wavelen[sort_idx]
     meylan.ew[*] = meylan.ew[sort_idx]
     matched_waves[*] = matched_waves[sort_idx]
     if type eq 'weak' then begin
        meylan.species[*] = meylan.species[sort_idx]
        meylan.loggf[*] = meylan.loggf[sort_idx]
     endif else begin
        meylan.loggfp[*] = meylan.loggfp[sort_idx]
        meylan.loggf79[*] = meylan.loggf79[sort_idx]
        meylan.loggf90[*] = meylan.loggf90[sort_idx]
        ;; Add the junks here if necessary.
     endelse
  endif

end

sso_solar_read
end
