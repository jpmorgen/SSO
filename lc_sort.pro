; +
;; $Id: lc_sort.pro,v 1.2 2015/03/03 20:08:43 jpmorgen Exp $

;; lc_sort
;;
;; Sort a line catalog by wavelength, src, and ptype.  If clean_dup is
;; set, redundant records are marked with a negative catalog number.
;; There is no attempt to determine the correct identification: the
;; first entry is assumed to be the "correct" one.

; -

function lc_sort, lc, mark_dup=mark_dup

  ;; Sort by wavelen
  widx = sort(lc.wavelen)
  nw = N_elements(widx)
  ;; Prepare return array
  sorted_idx = lonarr(nw)
  last_sorted = long(0)
  iw = long(0)
  first_iw = long(0)
  ;; Loop through each set of records with identical .wavelen
  while iw le nw - 1 do begin
     ;; Find how many records have this particular wavelength.
     wavelen = lc[widx[first_iw]].wavelen
     repeat begin
        if iw lt nw-1 then $
          iw = iw + 1
     endrep until lc[widx[iw]].wavelen ne wavelen or iw ge nw-1
     ;; We either found a non-matching record and/or the end of the
     ;; array.  In the former case, iw points to this first unmatching
     ;; record.  Back it up by one.
     if lc[widx[iw]].wavelen ne wavelen then begin
        iw = iw - 1
     endif
     ;; Sort the matching wavelength records by src and cast them back
     ;; onto the iw index space.
     src_idx = sort(lc[widx[first_iw:iw]].src) + first_iw
     ;; now put them into the original lc index space.
     src_idx = widx[src_idx]
     ns = N_elements(src_idx)
     si = long(0)
     first_si = long(0)
     ;;  Loop through src
     while si lt ns - 1 do begin
        repeat begin
           si = si + 1
           snomatch = lc[src_idx[si]].src ne lc[src_idx[first_si]].src 
        endrep until si ge ns - 1 or snomatch
        if snomatch then begin
           si = si - 1
        endif
        ;; General code for sorting using histogram reverse index method
        hist = histogram(lc[src_idx[first_si:si]].ptype, $
                         binsize=1, reverse_indices=r_idx)
        ;; Extract sorted array indices and mark duplicates using r_idx
        nbins = N_elements(hist)
        nidx = N_elements(lc[src_idx[first_si:si]].ptype)
        sidx = lonarr(nidx)
        sp = 0 ;; running position in sidx array
        for ibin=0, nbins-1 do begin
           bin_count = r_idx[ibin+1] - r_idx[ibin]
           if bin_count gt 0 then begin
              ;; bin_idx is the array of indices pointing to the
              ;; original array that was histogrammed.
              bin_idx = r_idx[ r_idx[ibin] : r_idx[ibin+1] - 1 ]
              ;; Put this bin's indices into sidx for final sort
              sidx[sp:sp+bin_count-1] = bin_idx
              sp = sp + bin_count
              
              ;; Code specific to lc_sort.  Recall here and below that
              ;; first_si is the first index of the array we have
              ;; histogrammed.
              if bin_count gt 1 then begin
                 if NOT keyword_set(mark_dup) then $
                   message, 'ERROR: records with identical wavelen, src, and ptype found.  Are you sure this is a single catalog you are trying to sort?  If you want to clean this catalog, set the /mark_dup keyword and use lc_clean_dup'
                 ;; Mark duplicates.  Assume the first one is the best
                 pidx = src_idx[r_idx[ r_idx[ibin] + 1 : r_idx[ibin+1] - 1 ] $
                               + first_si]
                 lc[pidx].cat = - lc[pidx].cat
              endif ;; Duplicates

           endif ;; bin_count gt 0
           
        endfor ;; Each r_idx

        sorted_idx[last_sorted:last_sorted+nidx-1] = src_idx[sidx + first_si]
        last_sorted = last_sorted + nidx
        si = si + 1
        first_si = si
     endwhile
     ;; Handle the case where there are not multiple entries for this wavelength
     if ns eq 1 then begin
        sorted_idx[last_sorted] = widx[iw]
        last_sorted = last_sorted + 1
     endif
     iw = iw + 1
     first_iw = iw
  endwhile ;; iw

  return, sorted_idx

end
