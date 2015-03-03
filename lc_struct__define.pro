; +
; $Id: lc_struct__define.pro,v 1.4 2015/03/03 20:08:55 jpmorgen Exp $

; lc_parinfo__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  Call explicitly with an
; if you need to have a default structure with different initial values.

;; Add on the lc specific tags to the pfo_parinfo structure.  Do this
;; with a single tag lc that refers to a structure so as to keep the
;; top parinfo level clean.

;; Tag		Meaning
;; cat		Current catalog number that this parameter is
;; 		considered a part.
;; ocat		Original catalog number from which this parameter
;; 		value comes. See lc_sysvar__define for catalog/number
;; 		correspondences
;; src		Source.  Several of the catalogs (e.g. Moore)
;; 		tabulate more than one kind of line (e.g. solar and
;; 		atmospheric).  This is catalog specific and should be
;; 		documented in the lc_read_* files.
;; wavelen	Wavelength of the line.  This is for identification
;; 		purposes only.  
;; serial	For lines with identical wavelength, allows unique
;; 		identification
;; version	Catalog version.  For the sso catalog, this is
;; 		continually improving.  Debated making this JD of
;; 		catalog publication date, but figured people would
;; 		document new catalog versions well.
;; name		Full name of the line (e.g. Atm H2O)
;; species	String containing the name of the emitting/absorbing
;; 		atom or molecule (Chianti has some cool routines for
;; 		handling these)
;; mweight	molar weight of species
;; ion_state	Ionization state in spectroscopic notation:
;;		0 = unspecified
;;		1 = neutral
;;		2 = singly ionized, etc.
;; ltype	A simple taxonomy of lines.  See lc_sysvar__define
;; ptype	Parameter type (e.g. wavelength in Angstroms,
;; 		equivalent width, in milliAngstroms etc.)  See
;; 		lc_sysvar__define for correspondences
;; value	Value of the parameter
;; error	Symmetric error bar value quoted in catalog
;; 		Together with quality determines how this value should
;; 		rank compared to other catalogs
;; limits	Lower and upper limits on value.  Unlike error, these
;; 		are absolute.  Absorption lines should have the upper
;; 		limit set to 0, e.g. limit=[!values.d_nan, 0]
;; quality	0=not assigned, 1=best, 2=good, 3=OK, 4=bad, 5=useless
;; path		See sso_dg_assign? A 10 element array containing
;; 		modified JPL ephemeris  
;; 		numbers of the source object, any intervening
;; 		reflections, and the object on which the detector was
;; 		mounted.  For the laboratory, path = [399,399], for
;; 		solar observations, path = [10, 399].  As of 2003, JPL
;; 		does not use the numbers 11-198, so they can be used
;; 		for some other path classification scheme.
;;
;;		   http://ssd.jpl.nasa.gov/horizons_doc.html
;; 
;; match	structure containing tags that help to merge two catalogs
;;

pro lc_struct__define, lc_struct=lc_struct
  lc_match_struct = {lc_match_struct}
  lc_struct $
    = {lc_struct, $
       cat		: 0,  $
       ocat		: 0,  $
       src		: 0,  $
       wavelen		: 0D, $
       serial		: 0,  $
       version		: 0,  $	;; Please document this in lc_read_*
       name		: '', $
       species		: '', $
       mweight		: 0D, $
       ion_state	: 0,  $
       ltype		: ulong64(0), $
       ptype		: 0,  $
       value		: 0D, $
       error		: 0D, $
       limits		: [0.D,0.D], $
       quality		: 0,  $ 
       path		: lonarr(10), $
       match		: lc_match_struct}

  lc_struct.wavelen = !values.d_nan
  lc_struct.mweight = !values.d_nan
  lc_struct.value = !values.d_nan
  lc_struct.error = !values.d_nan
  lc_struct.limits = [!values.d_nan, !values.d_nan]
  
end


