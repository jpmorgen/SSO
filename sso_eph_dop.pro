;+
; NAME: sso_eph_dop
;
;
;
; PURPOSE: Returns total ephemeris Doppler shift for light traveling
; along a path
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
; $Id: sso_eph_dop.pro,v 1.1 2015/03/03 20:14:22 jpmorgen Exp $
;-

function sso_eph_dop, UT, in_path, opoint, ltime=ltime_out

  init = {sso_sysvar}

  total_dop = 0d
  ltime_out = 0d
  if N_elements(in_path) eq 0 then $
    return, total_dop

  ;; Make sure we have at least two things in our path to calculate
  ;; the Doppler shift between
  if in_path[0] eq !sso.aterm then $
    return, total_dop
  if in_path[1] eq !sso.aterm then $
    return, total_dop

  ;; Because of light travel times, calculation must be done starting
  ;; from the observing body, where we have registered the time.
  ;; Also, get rid of trailing !sso.aterm elements of array.
  rpath = reverse(in_path)
  good_idx = where(rpath ne !sso.aterm, npath)
  rpath = long(rpath[good_idx])

  ;; Make sure kernels are loaded
  eph_load_kernels, UT, rpath

  ;; Convert to ephemeris time.  Let the cspice routines catch UT
  ;; formatting errors
  cspice_str2et, UT, et


  ;; Calculate the state of the observing object body center
  cspice_spkapp, rpath[0], et, 'J2000', !eph.s_ssb, 'NONE', $
                 s_ssb_o1, junk
  ;; Modify this for an observation point on the surface of the body
  if N_elements(opoint) ne 0 then begin
     ;; Make opoint a state vector
     while N_elements(opoint) lt 6 do $
       opoint = [opoint, 0]
     ;; make sure it is double
     opoint = double(opoint)
     ;; Check for silly overspecification
     if total(opoint[!eph.v_idx]) ne 0 then $
       message, 'ERROR: observer point cannot have a velocity relative to the center of its body'

     ;; opoint is now a reasonable state vector specifying the state
     ;; of the observation point relative to the center of the
     ;; observing body in the reference frame of that body.  SPICE
     ;; lets you create a transformation from an inertial state to a
     ;; bodyfixed state.  Invert that to get what I want.  Using
     ;; tisbod rather than sxform lets me use numbers instead of names
     ;; + saves the step of looking up the body fixed frame of
     ;; rpath[1]
     cspice_tisbod, 'J2000', rpath[0], et, t_j2k_o1
     t_o1_j2k = invert(t_j2k_o1)

     ;; Use IDL-native matrix multiplication, but make sure the
     ;; results are in the form SPICE likes
     s_o1_obs = transpose(t_o1_j2k) # opoint

     s_ssb_o1 = s_ssb_o1 + s_o1_obs

  endif ;; Observer on surface of body
     
  for i=1, npath-1 do begin
     cspice_spkapp, rpath[i], et, 'J2000', s_ssb_o1, 'LT+S', s_o1_o2, ltime
     ;; Get the radial velocity between these two points using the dot
     ;; product of the unit vector pointing from o1 to o2 and the
     ;; velocity vector
     total_dop = total_dop + $
                 transpose(s_o1_o2[!eph.p_idx]/norm(s_o1_o2[!eph.p_idx])) # $
                 s_o1_o2[!eph.v_idx]
     ;; Accumulate our total light time until we get back to the
     ;; original source
     ltime_out = ltime_out + ltime
     ;; If this object is bouncing light, set et to the time of bounce
     ;; and make a state vector for use next time around in the loop
     if i lt npath then begin
        et = et - ltime
        cspice_spkapp, rpath[i], et, 'J2000', !eph.s_ssb, 'NONE', s_ssb_o1, junk
     endif
  endfor ;; Each light source on light path.

  return, total_dop

end
