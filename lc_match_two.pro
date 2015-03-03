; +
;; $Id: lc_match_two.pro,v 1.5 2015/03/03 20:08:06 jpmorgen Exp $

;; lc_match_two
;;
;; Fill in the lc match struct to store match information between two
;; line catalogs.  Assumes that the catalogs are pre-sorted by
;; wavelength and have no duplicate entries.  Nclose is the number of
;; nearest neighbor elements to consider in the match, maxdiff is the
;; maximum difference in wavelength that a match will tolerate.

;; /milli displays wavelength diffrences in milliangstroms (maxdiff is
;; also assumed to be in mA).  milli can also be set to another
;; exponent, e.g. milli=6

; -

pro lc_match_two, ca1, ca2, nclose=nclose, close_mult=close_mult, $
                  maxdiff=in_maxdiff, xrange=xrange, yrange=yrange, $
                  maxprint=maxprint, milli=milli

  init = {lc_sysvar}
  init = {tok_sysvar}
  init = {eph_sysvar}
  init = {pfo_sysvar}

  if N_elements(maxprint) eq 0 then $
    maxprint = 100

  ;; Make sure we don't change input maxdiff
  if N_elements(in_maxdiff) ne 0 then $
    maxdiff = in_maxdiff

  ;; Find the three lines from the second catalog that are closest to
  ;; each line in the first.  Just look at the wavelength records,
  ;; which complicates things a bit....
  c1wrecs = where(ca1.ptype eq !lc.wavelen)
  c2wrecs = where(ca2.ptype eq !lc.wavelen)

  ;; Clear out the match structures.  IDL6 complains unless we match
  ;; the array sizes
  ca1.match = replicate(!lc.lc_struct.match, N_elements(ca1))
  ca2.match = replicate(!lc.lc_struct.match, N_elements(ca2))

  ;; Handle /milli and e.g., milli=6
  if N_elements(milli) eq 0 then $
    milli = 0
  millie = milli
  if milli eq 1 then $ ;; /milli
    millie = 3

  ;; Calculate maxdiff based on the median distance between catalog
  ;; entries
  d1 = median(ca1[c1wrecs[1:N_elements(c1wrecs)-1]].wavelen - $
              ca1[c1wrecs[0:N_elements(c1wrecs)-2]].wavelen)
  d2 = median(ca2[c2wrecs[1:N_elements(c2wrecs)-1]].wavelen - $
              ca2[c2wrecs[0:N_elements(c2wrecs)-2]].wavelen)
  if N_elements(maxdiff) eq 0 then begin
     maxdiff = (min([d1, d2])/2.) * 10^float(millie)
  endif

  if N_elements(close_mult) eq 0 then $
    close_mult = 5
  if N_elements(nclose) eq 0 then begin
     nclose = round(max([close_mult, close_mult * d1/d2]))
  endif


  message, /CONTINUE, 'Comparing ' + !lc.cat_names[ca1[0].cat] + ' and ' + !lc.cat_names[ca2[0].cat] + ' lines between ' + strtrim(min([ca1.wavelen, ca2.wavelen]), 2) + ' and ' + strtrim(max([ca1.wavelen, ca2.wavelen]), 2) + ' angstroms'
  print, 'Median distance between points (Angstroms)'
  print, '   ', !lc.cat_names[ca1[0].cat], ': ', strtrim(d1, 2)
  print, '   ', !lc.cat_names[ca2[0].cat], ': ', strtrim(d2, 2)
  millis = ''
  if keyword_set(milli) then $
    millis = 'milli'
  print, 'Using maxdiff = ' + strtrim(maxdiff, 2) + ' ', millis, 'Angstroms'
  print, 'Searching nclose = ', strtrim(nclose, 2), $
         ' points in ', !lc.cat_names[ca2[0].cat], ' for each point in ', $
         !lc.cat_names[ca1[0].cat]
  print, 'Printing no more than maxprint = ', strtrim(maxprint, 2), ' lines'

  ;; This has to be in font !3 for the angstrom symbol to be found
  xtitle = 'Wavelength (' + string("305B)+')' ;" ;
  ytitle = 'Wavelenth Difference ('+ millis + string("305B)+')' ;" ;

  maxdiff = maxdiff * 10^float(-millie)


  u_src = uniq(ca1.src, sort(ca1.src))
  nsrc = N_elements(u_src)
  nsrc2plot = 0
  for isrc=0, nsrc - 1 do begin

     src = ca1[u_src[isrc]].src
     s1idx = where(ca1[c1wrecs].src eq src, nsrc1)
     s2idx = where(ca2[c2wrecs].src eq src, nsrc2)
     if nsrc1 eq 0 or nsrc2 eq 0 then $
       CONTINUE
     ;; unnest
     s1idx = c1wrecs[s1idx]
     s2idx = c2wrecs[s2idx]

     ;; Assume that the catalogs are already sorted
     i = long(0)
     ii = long(0)
     closest = lindgen(nclose) - nclose/2
     ;; Loop through each entry in catalog 1
     repeat begin
        idx1 = s1idx[i]

        ;; Start from where we left off on catalog 2 to find a match.
        ;; Set the center of our search area in catalog 2 to be just
        ;; beyond the wavelength of our catalog 1 entry.
        repeat begin
           if ii lt nsrc2-1 then $
             ii = ii + 1
           idx2 = s2idx[ii]
           diff = ca2[idx2].wavelen - ca1[idx1].wavelen
        endrep until diff gt 0 or ii eq nsrc2 - 1

        ;; If we are at the end of catalog 2, ii = the closest,
        ;; otherwise, ii-1 is the closest
        c2idx = closest + ii
        bad_idx = where(c2idx lt 0 or c2idx ge nsrc2, count, $
                        complement=good_idx)
        if count gt 0 then $
          c2idx = c2idx[good_idx]
        c2idx = s2idx[c2idx]

        ;; Here is where we find the minimum difference
        diffs = ca2[c2idx].wavelen - ca1[idx1].wavelen
        sd_idx = sort(abs(diffs))
        idx2 = c2idx[sd_idx[0]]
        diff = ca1[idx1].wavelen - ca2[idx2].wavelen
        if abs(diff) le maxdiff then begin
           ;; Check for a previous match
           if ca2[idx2].match.cat ne 0 then begin
              ;; If previous the match is better, keep it by looking
              ;; up the old value of idx2.  Otherwise, the new idx2
              ;; will be used.
              if abs(diff) gt abs(ca2[idx2].match.diff) then $
                idx2 = ca1[ca2[idx2].match.idx].match.idx
           endif
           ca1[idx1].match.idx = idx2
           ca1[idx1].match.cat = ca2[idx2].cat
           ca2[idx2].match.idx = idx1
           ca2[idx2].match.cat = ca1[idx1].cat
           ca1[idx1].match.diff = diff
           ca2[idx2].match.diff = -diff
        endif ;; diff not too big
        ii = ii - 1
        i = i + 1
     endrep until i ge nsrc1

     ;; If we made it here, we probably have something worth reporting
     nsrc2plot = nsrc2plot + 1

     ;; Now go back over catalog 1 and check for duplicate matches.
     ;; These should always be in order if the catalogs were sorted.
     m1_idx = where(ca1[s1idx].match.cat eq ca2[0].cat, nmatch)
     if nmatch eq 0 then $
       CONTINUE

     ;; unnest
     m1_idx = s1idx[m1_idx]

     ;; NOTE: reusing idx1 and idx2

     ;; Use histogram reverse indices of the match idx.  The indices
     ;; of m1_idx are taked onto the end of an array that references
     ;; itself (a little confusing).
     if N_elements(m1_idx) gt 1 then begin
        hist = histogram(ca1[m1_idx].match.idx, binsize=1, reverse_indices=r1_idx)
        for im=long(0), N_elements(hist)-1 do begin
           ;; Bail if there are no duplicates
           ndup = r1_idx[im+1] - r1_idx[im]
           if ndup le 1 then $
             CONTINUE
           dup_idx = m1_idx[r1_idx[r1_idx[im]:r1_idx[im+1]-1]]
           junk = min(abs(ca1[dup_idx].match.diff), idx1)
;        plot, abs(ca1[dup_idx].match.diff), title=idx1
;        wait, 1
           ;; unnest
           idx1 = dup_idx[idx1]
           ;; Save best match
           idx2 = ca1[idx1].match.idx
           diff = ca1[idx1].match.diff
           ;; Nuke all matches
           ca1[dup_idx].match = replicate(!lc.lc_struct.match, ndup)
           ;; Restore best match
           ca1[idx1].match.cat = ca2[0].cat
           ca1[idx1].match.idx = idx2
           ca1[idx1].match.diff = diff
           ;; We don't need to worry about ca2, since we make sure not to
           ;; nuke the smallest diff 
        endfor ;; Sets of matches
     endif ;; Enough matches to do a histogram
  endfor ;; each source
     

  ;; Present results of match.
  
  !p.multi = [0,2,nsrc2plot]
  for isrc=0, nsrc - 1 do begin
     print, '****************************************************'
     src = ca1[u_src[isrc]].src
     s1_idx = where(ca1[c1wrecs].src eq src, nsrc1)
     s2_idx = where(ca2[c2wrecs].src eq src, nsrc2)
     if nsrc1 eq 0 or nsrc2 eq 0 then $
       CONTINUE
     ;; unwrap
     s1_idx = c1wrecs[s1_idx] 
     s2_idx = c2wrecs[s2_idx] 
     match_idx = where(ca1[s1_idx].match.cat ne 0, nmatch, $
                       complement=nomatch_idx, ncomplement=nnomatch)
     title = !lc.cat_names[ca1[0].cat] + ' -  ' + !lc.cat_names[ca2[0].cat] + $
             ', source = ' + !eph.names[src]
     print, 'source = ' + !eph.names[src]
     print, !lc.cat_names[ca1[0].cat], ': ', strtrim(nsrc1, 2), ' lines'
     print, !lc.cat_names[ca2[0].cat], ': ', strtrim(nsrc2, 2), ' lines'
     print, 'Matches: ', strtrim(nmatch, 2)
     print, 'Non-matching (from ', !lc.cat_names[ca1[0].cat], '): ', $
            strtrim(nnomatch, 2)
     print, 'Non-matching (from ', !lc.cat_names[ca2[0].cat], '): ', $
            strtrim(nsrc2 - nmatch, 2)

     if nmatch gt 1 then begin
        match_idx = s1_idx[match_idx]
        plot, ca1[match_idx].wavelen, $
              ca1[match_idx].match.diff * 10^float(millie), $
              psym=!tok.plus, xrange=xrange, yrange=yrange, $
              title=title, xtitle=xtitle, ytitle=ytitle
        if nmatch lt maxprint then begin
           print, 'Matching entries sorted by wavelength'
           print, '++++++++++++++++++++++++++++++++++++++++++++++++++++'
           for il=0, nmatch-1 do begin
              c1idx = match_idx[il]
              c2idx = ca1[c1idx].match.idx
              print, ca1[c1idx].wavelen, ' ',ca1[c1idx].name ;, $
              print, ca2[c2idx].wavelen, ' ',ca2[c2idx].name
              print, '++++++++++++++++++++++++++++++++++++++++++++++++++++'
           endfor
           print, 'Matching entries sorted by abs(diff)'
           print, '----------------------------------------------------'
           sidx = sort(abs(ca1[match_idx].match.diff))
           ;; CAUTION: Reusing match_idx
           match_idx = match_idx[sidx]
           for il=0, nmatch-1 do begin
              c1idx = match_idx[il]
              c2idx = ca1[c1idx].match.idx
              print, ca1[c1idx].wavelen, ' ',ca1[c1idx].name ;, $
              print, ca2[c2idx].wavelen, ' ',ca2[c2idx].name
              print, '----------------------------------------------------'
           endfor
        endif ;; Not too many to print
     endif ;; Matches found

     ;; Catalog 1 unmached entries
     if nnomatch gt 0 then begin
        nomatch_idx = s1_idx[nomatch_idx]
        nomatch = intarr(nnomatch)
        oplot, [ca1[nomatch_idx].wavelen], nomatch, psym=!tok.triangle
        if nnomatch lt maxprint then begin
           print, 'Entries in ', !lc.cat_names[ca1[0].cat], ' that find no match in ', !lc.cat_names[ca2[0].cat]
           for il=0, nnomatch-1 do begin
              print, ca1[nomatch_idx[il]].wavelen, ' ', $
                     ca1[nomatch_idx[il]].name
           endfor
        endif ;; Not too many to print
     endif ;; Non-matching entries found

     ;; Catalog 2 unmached entries
     nomatch_idx = where(ca2[s2_idx].match.cat eq 0, nnomatch)

     if nnomatch gt 0 then begin
        nomatch_idx = s2_idx[nomatch_idx]
        nomatch = intarr(nnomatch)
        oplot, [ca2[nomatch_idx].wavelen], nomatch, psym=!tok.dot
        if nnomatch lt maxprint then begin
           print, 'Entries in ', !lc.cat_names[ca2[0].cat], ' that find no match in ', !lc.cat_names[ca1[0].cat]
           for il=0, nnomatch-1 do begin
              print, ca2[nomatch_idx[il]].wavelen, ' ', $
                     ca2[nomatch_idx[il]].name
           endfor
        endif ;; Not too many to print
     endif ;; Non-matching entries found

     legend, ['Wavelength difference', $
              !lc.cat_names[ca1[0].cat] + ' Non-matching', $
              !lc.cat_names[ca2[0].cat] + ' Non-matching'], $
             psym=[!tok.plus, !tok.triangle, !tok.dot]

     ;; Plot histogram
     if nmatch gt 1 then begin
        hist = histogram(ca1[match_idx].match.diff * 10^float(millie), $
                         locations=xaxis, nbins=max([nmatch/10, 10]))
        htitle = title + ', [' + $
                 strtrim(min([ca1.wavelen, ca2.wavelen]), 2) + $
                 ', ' + strtrim(max([ca1.wavelen, ca2.wavelen]), 2) + $
                 '] ' + string("305B) ;" ;
        hist = hist/(xaxis[1]-xaxis[0])
        plot, xaxis, hist, title=htitle, $
              xtitle=ytitle, ytitle='Number per bin'
        

        ;; Fit histogram
        parinfo = pfo_fcreate(!pfo.voigt, format='f8.2', eformat='e10.3')
        to_pass = {parinfo:parinfo}
        params = mpfitfun('pfo_funct', xaxis, hist, parinfo=parinfo, $
                          functargs=to_pass, autoderivative=1, quiet=1, $
                          iterproc='pfo_iterproc', perror=perror, $
                          status=status)
        if status le 0 then $
          message, 'ERROR: MPFIT has not returned to the MAIN level, but rather to here'
        message, 'MPFITFUN returned STATUS ' + strtrim(status,2), /CONTINUE

        parinfo.value = params
        parinfo.error = perror

        yfit = pfo_funct(xaxis, params, parinfo=parinfo)
        
        oplot, xaxis, yfit

        ;; Note that params is optional once value is assigned correctly
        print, 'Parameters of fit to histogram'
        print, pfo_funct([0], parinfo=parinfo, print=!pfo.pmp)


     endif ;; calculating histogram if matches


  endfor ;; Each source
  !p.multi = 0

end
