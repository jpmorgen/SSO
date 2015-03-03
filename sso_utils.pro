; +
; $Id: sso_utils.pro,v 1.1 2015/03/03 20:16:07 jpmorgen Exp $

; sso_utils.pro  A collection of primitive routines use in the sso
; package.  See sso_init.pro.  I am playing a little trick with
; keyword_set and N_elements.  When things can either be an array or a
; scaler, they break comparison statements.  keyword_set and
; N_elements (and size) return sensible results regardless of the type
; of their arguments.

; -

;; sso_get_tag_idx

;; sso_make_null.  This is actually a more-or-less general routine for
;; IDL >= 5 that sets the input variable to a value recognizable by
;; sso_is_null.  Care is taken with structures and arrays to set each
;; element to its respective null value.  The one exception that I
;; cannot get around is when you pass an array or structure element,
;; instead of the whole array.  In this case, you have to make a
;; temporary variable consisting of just that element, set it to null
;; and then insert it back into the structure.  To aid this, you can
;; pass the whole array and specify the idx argument.  The same goes
;; for structures with the tags= argument.  Tags can be passed as the
;; tag numbers, verbatim string, or a regular expression

pro sso_make_null, output, idx, tags=tags
  ;; IDX lets us pick out particular elements of an array to null.
  ;; Passing an expression like sso_make_null, t[4] does not work,
  ;; since a copy of t[4] is made and passed
  if NOT keyword_set(idx) then begin
     idx = lindgen(N_elements(output))
  endif
  for i=0,N_elements(idx)-1 do begin
     tmp = output[idx[i]]
     ;; Just in case IDL ever lets us make arrays with elements of
     ;; differing type, do the typecoding here.
     typecode = size(tmp, /type)
     case typecode of
        0  : return ;; Undefined
        1  : tmp = byte(!values.d_nan)
        2  : tmp = fix(!values.d_nan) ;; integer
        12  : tmp = uint(!values.d_nan) ;; unsigned integer
        3  : tmp = longint(!values.d_nan)
        13  : tmp = ulong(!values.d_nan)
        14  : tmp = long64(!values.d_nan)
        15  : tmp = ulong64(!values.d_nan)
        4  : tmp = float(!values.d_nan)
        5  : tmp = double(!values.d_nan)
        6  : tmp = complex(!values.d_nan, !values.d_nan)
        7  : tmp = 'SSO NULL STRING'
        8  : begin
           ;; Allow tag names or numbers to be passed, just in case we
           ;; want to null a particular field, instead of the whole
           ;; structure.  Code this efficiently, since it gets
           ;; executed a lot.  If tags is not set, the whole loop gets
           ;; skipped.
           for it=0,N_elements(tags)-1 do begin
              ;; Just in case this ever changes mid array 
              if size(tags[it], /type) eq 7 then begin
                 ;; Assume tags[it] is a regular expression + match it
                 ;; in all of the tags
                 if NOT keyword_set(all_tags) then $
                   all_tags = tag_names(tmp)
                 match_idx $
                   = where(stregex(all_tags, tags[it], $
                                   /boolean, /fold_case), $
                           count)
                 if count gt 0 then $
                   sso_append_array, tag_idx, match_idx
              endif else begin
                 sso_append_array, tag_idx, tags[it]
              endelse
           endif
           ;; Make sure not to forget the case where we had no tag matches
           if NOT keyword_set(tag_idx) then begin
              tag_idx = lindgen(N_tags(output))
           endif
           
           for it=0,N_elements(tag_idx)-1 do begin
              field = tmp.(tag_idx[it])
              sso_make_null, field
              tmp.(tag_idx) = field
           endfor
        end
        9  : tmp = dcomplex(!values.d_nan, !values.d_nan)
        else : message, 'ERROR: I do not know how to make a NULL of type ' + string(size(tmp, /tname))
     endcase
     output[idx[i]] = tmp
  endfor
end

function sso_is_null, input


  ;; For now, I am just using 0 as null, though at some point, I might
  ;; get fancier.  Make sure to use this primitive so that things can
  ;; be changed
  return, keyword_set(parinfo)
end

function sso_init_poly, in_orders, in_refs
  ;; Check to see if our reference points are defined
  n_refs = N_elements(in_refs)
  for ref_idx = 0,n_refs-1 do begin
     new_parinfo = append_parinfo(!sso.parinfo)
  endfor

  num_polys = size(in_orders, /DIMENSIONS)
  ;; num_polys = 0 means in_orders is a scaler and we are just making a
  ;; single polynomial
  if NOT keyword_set(num_polys) then begin
     parinfo = replicate(!sso.parinfo, in_orders+1)
     for o_idx=0,in_order do begin
        zeros = o_idx / 10
        parinfo.sftype = !sso.ftype.poly + !sso.ptype.polyseg + o_idx*10^(-2.-zeros)
     endfor
     return, parinfo
  endif
  return, parinfo
end

;function sso_init_f, ssoftype, ssoID, ssounit, ssosrc, ssoltype, ssorwl, ssoowl, ssodop, ssovalue, ssosID, ssoion, ssolID, ssocomment
;
;  
;
;end
