; +
;; $Id: lc_merge_two.pro,v 1.1 2015/03/03 20:08:16 jpmorgen Exp $

;; lc_merge_two
;;
;; Takes the output of lc_match_two (the two original catalogs) and
;; combines them into a new catalog with lc catalog number newcat.
;; The line that ends up in the new catalog is the one with the best
;; quality ranking (e.g. 1).  If the qualities are equal, catalog 2
;; will be prefered.  Since the catalogs had to be sorted for
;; lc_match_two, assume they are still sorted here.


; -

function lc_merge_two, ca1, ca2, newcat_num

  init = {lc_sysvar}
  init = {tok_sysvar}
  init = {eph_sysvar}
  
  bad_idx = where(ca1.quality eq 0, n1)
  bad_idx = where(ca2.quality eq 0, n2)
  if n1 + n2 ne 0 then $
    message, 'ERROR: quality flag is not assigned on all the parameters'

  nca1 = N_elements(ca1)
  nca2 = N_elements(ca2)

  ;; In IDL, it is faster to make a large array an then chop it down
  ;; that build it up one element at a time.
  newcat = make_array(nca1 + nca2, value=!lc.lc_struct)
  inc = long(0)

  ;; Put all the unmatching records from ca1 and ca2 directly into
  ;; newcat.  Make sure to drag all the parameters in (width, etc.)
  ;; for each line.
  lc_idx = where(ca1.ptype eq !lc.wavelen)
  nomatch_idx = where(ca1[lc_idx].match.cat eq !lc.none, nnomatch)
  for inm=long(0), nnomatch-1 do begin
     idx = lc_idx[nomatch_idx[inm]]
     w = ca1[idx].wavelen
     s = ca1[idx].src
     repeat begin
        newcat[inc] = ca1[idx]
        inc = inc + 1
        idx = idx + 1
        tw = !values.d_nan
        ts = !values.d_nan
        if idx lt nca1 then begin
           tw = ca1[idx].wavelen
           ts = ca1[idx].src
        endif
     endrep until tw ne w or ts ne s
  endfor ;; each unmatched line
  lc_idx = where(ca2.ptype eq !lc.wavelen)
  nomatch_idx = where(ca2[lc_idx].match.cat eq !lc.none, nnomatch)
  for inm=long(0), nnomatch-1 do begin
     idx = lc_idx[nomatch_idx[inm]]
     w = ca2[idx].wavelen
     s = ca2[idx].src
     repeat begin
        newcat[inc] = ca2[idx]
        inc = inc + 1
        idx = idx + 1
        tw = !values.d_nan
        ts = !values.d_nan
        if idx lt nca2 then begin
           tw = ca2[idx].wavelen
           ts = ca2[idx].src
        endif
     endrep until tw ne w or ts ne s
  endfor ;; each unmatched line

  ;; Put the matching records into newcat.  Only the wavelength
  ;; records are matched, so we can skip the step of finding the line
  ;; centers.  Decide which parameters to put in based on the quality
  ;; ranking
  m1_idx = where(ca1.match.cat ne !lc.none, nmatch)
  for im1=0, nmatch-1 do begin
     ;; Mark first entry in newcat of this line so we can get wavelen
     ;; standardized when all the records are mixed together
     iinc = inc
     i1 = m1_idx[im1]
     w1 = ca1[i1].wavelen
     s1 = ca1[i1].src
     im2 = ca1[i1].match.idx
     w2 = ca2[im2].wavelen
     s2 = ca2[im2].src
     ;; For each ca1 parameter of this line, cycle through all the ca2
     ;; parameters to see if we have a better quality for the one that
     ;; matches our current ca1 parameter.  On long line lists, this
     ;; is much faster than whereing the whole list for wavelength
     ;; matches.
     repeat begin
        i2 = im2 ; Reset i2 for each i1
        repeat begin
           ;; Find common records in both catalogs + put the best one
           ;; in newcat.  Mark these so that non-matching records from
           ;; both catalogs can be inserted as well.  Make sure not to
           ;; put matches in more than once, but wavelength has to be
           ;; put in once.
           if ca1[i1].ptype eq ca2[i2].ptype and $
             (ca1[i1].match.cat eq !lc.none or $
              ca1[i1].ptype eq !lc.wavelen) then begin
              ;; Mark matching entries so we can pick up non-matching
              ;; entries below.  This should not harm wavelength
              ;; records.
              ca1[i1].match.cat = ca2[i2].cat
              ca1[i1].match.idx = i2
              ca2[i2].match.cat = ca1[i1].cat
              ca2[i2].match.idx = i1
              ;; Put best record in newcat.  Sorry, quality ranking
              ;; looks backwards.  Low number is highest quality.  If
              ;; they are equal, prefer catalog 2
              if ca1[i1].quality lt ca2[i2].quality then begin
                 newcat[inc] = ca1[i1]
              endif else begin
                 newcat[inc] = ca2[i2]                 
              endelse
              inc = inc + 1
           endif ;; Matching ptypes
           i2 = i2 + 1
           tw2 = !values.d_nan
           ts2 = !values.d_nan
           if i2 lt nca2 then begin
              tw2 = ca2[i2].wavelen
              ts2 = ca2[i2].src
           endif
        endrep until tw2 ne w2 or ts2 ne s2
        ;; Leave i2 at the end of the string of records
        i2 = i2 - 1

        i1 = i1 + 1
        tw1 = !values.d_nan
        ts1 = !values.d_nan
        if i1 lt nca1 then begin
           tw1 = ca1[i1].wavelen
           ts1 = ca1[i1].src
        endif
     endrep until tw1 ne w1 or ts1 ne s1
     ;; Leave i1 at the end of the string of records
     i1 = i1 - 1
     
     ;; Matched records are now marked and dumped into newcat.  Dump
     ;; non-matched records in.
     ca1_idx = where(ca1[m1_idx[im1]:i1].match.cat eq !lc.none, nnomatch)
     if nnomatch gt 0 then begin
        ;; unnest
        ca1_idx = m1_idx[im1] + ca1_idx
        newcat[inc:inc+nnomatch-1] = ca1[ca1_idx]
        inc = inc + nnomatch
     endif
     ca2_idx = where(ca2[im2:i2].match.cat eq !lc.none, nnomatch)
     if nnomatch gt 0 then begin
        ;; unnest
        ca2_idx = im2 + ca2_idx
        newcat[inc:inc+nnomatch-1] = ca2[ca2_idx]
        inc = inc + nnomatch
     endif

     ;; Set the wavelength of this string of records to the best
     ;; wavelength value (allows slight tweaking of wavelength values
     ;; without messing up matches)
     newcat[iinc:inc-1].wavelen = newcat[iinc].value

  endfor ;; Each matched ca1 line

  ;; Put the original catalog numbers in ocat (don't overwrite ones
  ;; that where there already) and put the new catalog number in cat.
  ;; Here is where I might want an array or linked list of the history
  ;; of the catalog numbers.
  new_idx = where(newcat.ocat eq !lc.none, nnew)
  if nnew gt 0 then $
    newcat[new_idx].ocat = newcat[new_idx].cat
  newcat.cat  = newcat_num 

  return, newcat[lc_sort(newcat[0:inc-1])]

end

