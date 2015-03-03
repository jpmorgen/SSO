; +
; $Id: sso_dg_assign.pro,v 1.2 2015/03/03 20:15:03 jpmorgen Exp $

; sso_dg_assign.pro 

;; This is a routine that helps handle Doppler groups in the SSO code.
;; Doppler groups are most efficiently handled with integer tokens
;; (e.g. rest frame = 0, Io = 1, reflected sunlight = 2, etc.)  that I
;; call Doppler groups (dg).  Keeping track of all the reflections is
;; a bit of a pain if you just have one integer.  This is where the
;; path concept comes in handy.  sso.path (also lc.path) is an array
;; of integers that represent the target off of which the light is,
;; bouncing.  The integers are taken from the JPL ephemerides program,
;; with 10 representing the Sun, 199, Mercury, 301 the Moon, etc.
;;
;;                 http://ssd.jpl.nasa.gov/horizons_doc.html
;;
;; The source and destination of the light is also recorded, so the
;; minimum number of elements in a path specification is 2.  For the
;; laboratory, path = [399,399], for solar observations, path = [10,
;; 399].  As of 2003, JPL does not use the numbers 11-198, so they can
;; be used for some other path classification scheme.

;; WARNING!  You must pass the entire parinfo array (not a subset of
;; it) for assignments of parinf.sso.dg to stick (see IDL
;; documentation on passing by reference vs passing by copying).  If
;; you really want a sub-array to be affected, use idx=

; -

pro sso_dg_assign, parinfo, idx, clear=clear, count=count

  init = {sso_sysvar}

  count = 0

  ;; Clean up the heap variables in !sso.dgs
  if keyword_set(clear) then begin
     while !sso.dgs ne ptr_new() do begin
        ;; pop things off the front of the list
        t = !sso.dgs
        !sso.dgs = (*t).next
        ptr_free, t
     endwhile
     return
  endif

  ;; Otherwise, add paths to !sso.dgs

  ;; Pathological case, avoids lindgen(0) error
  if N_elements(parinfo) eq 0 then $
    return

  ;; Set up idx if none specified
  if N_elements(idx) eq 0 then $
    idx = lindgen(N_elements(parinfo))


  for iidx=long(0), N_elements(idx)-1 do begin
     ipfo = idx[iidx]
     path = parinfo[ipfo].sso.path
     if sso_path_dg(path) eq -1 then begin
        ;; Add a new element to !sso.dgs.  Use a dynamically
        ;; assignable dg_struct
        new = (*!sso.dg_struct_ptr)
        ;; Increment Doppler group by one for each new path
        new.dg = 1
        if !sso.dgs ne ptr_new() then $
          new.dg = (*!sso.dgs).dg + 1
        new.path = path
        new.names = sso_path_names(path)
        new.next = !sso.dgs
        !sso.dgs = ptr_new(new, /allocate_heap, /no_copy)
     endif ;; adding new element to !sso.dg
     ;; put this path's dg into parinfo record for handy reference.
     parinfo[ipfo].sso.dg = sso_path_dg(path)

  endfor ;; Each element in parinfo
  
  ;; Make sure we have one and only one Doppler shift parameter for
  ;; each non-zero path.
  dgs = parinfo.sso.dg
  ptypes = parinfo.sso.ptype
  ;; Find the list of unique Doppler groups we are using and step
  ;; through it one by one looking for a Doppler shift parameter
  ;; somewhere within the idx window.
  u_dgs = uniq(dgs[idx], sort(dgs[idx]))
  for idg=0, N_elements(u_dgs)-1 do begin
     dg = dgs[idx[u_dgs[idg]]]
     if dg eq 0 then CONTINUE
     ;; Here is where we count the number of non-zero Doppler groups
     ;; in !sso.dgs
     count = count + 1
     dop_idx  = where(ptypes[idx] eq !sso.dop and $
                      dgs[idx] eq dg,  ndop)
     ;; If we are missing a Doppler shift parameter, make one and fix
     ;; it to 0.
     if ndop eq 0 then begin
        dop_parinfo = sso_fcreate(!sso.dop, parinfo_template=parinfo, $
                                  path=sso_dg_path(dg), value=0, fixed=1)

        ;; Add this Doppler parameter to parinfo (and its idx too!).
        ;; Rather than try to recover mid stride, just call ourselves
        parinfo = [parinfo, dop_parinfo]
        idx = [idx, N_elements(parinfo)-1]
        sso_dg_assign, parinfo, idx
        return
     endif
     ;; If we have too many Doppler shift parameters, mark all but the
     ;; first for deletion
     if ndop gt 1 then $
       parinfo[dop_idx[1:ndop-1]].pfo.status = !pfo.delete
     
     ;; Assign a name to the Doppler shift parameter's primitive
     parinfo[dop_idx].sso.pfo.parname = !sso.ptnames[!sso.dop] + ' ' + $
       strjoin(sso_dg_path(dg, /name), '-')
  endfor
end
