; +
; $Id: sso_init.pro,v 1.1 2015/03/03 20:18:40 jpmorgen Exp $

; Initialize the Fitting of Optical Spectroscopic Observations of
; Solar System Objects (FOSOSSO, or 'SSO for short) environment.  This
; primarily consists of (1) documentation, (2) setting the !sso system
; variable, and (3) defining some primitive routines for handling the
; sso.parinfo structure.

; At this point, SSO is just a collection of handy routines that let
; you build functions in a tinkertoy-like fashion and pass them to 
; mpfitfun, a curve-fitting package written by Craig Markwardt:
;
; http://cow.physics.wisc.edu/~craigm/idl/idl.html
;
; In my opinion, the major breakthrough that Craig made in the mpfit
; package was to create the "parinfo" structure, which allows
; information such as initial values, limits, algebraic relations
; between parameters, etc., to be passed to the fitting routine in a
; very robust and compact way.  This package extends this idea to the
; fitting function definition level.  The function MYFUNCT becomes a
; general parinfo parsing engine that reads PARINFO.* tags to figure
; out how to put together the desired function.  Analogous engines can
; be used for parameter display, plot annotation, parameter database
; storage and retrieval, etc.  Because of the broad class of problems
; the mpfit package applies to, it would not be desirable to write a
; general routine to do this.  Rather, specific problems that need
; this level of flexibility should define their own set of PARINFO
; tags and their own parsing engines.  This package handles one such
; case: high-resolution optical spectra of solar system objects.  A
; common feature of optical observations of solar system objects is
; reflected sunlight, in particular, contamination from the solar
; Fraunhoffer lines.  With sufficiently high resolution, good signal
; to noise and a good catalog, these lines can be fit and their effect
; removed.
;
; The idea is to build a structure that is usable direcly with
; mpfitfn, but can also be used in via some intermediate routines that
; take care of trivial calculations like Doppler shifts .  It seems
; like the parinfo structure is the natural place for this.  So far,
; the mpfit package defines:

;     .VALUE - the starting parameter value (I use params instead)
;     .FIXED - a boolean value;  
;     .LIMITED - a two-element boolean array.
;     .LIMITS - a two-element float or double array
;     .PARNAME - a string, giving the name of the parameter.
;     .STEP - the step size for numerical derivatives.  0=autodetect
;     .MPSIDE - the sidedness of the finite difference
;     .MPMAXSTEP - the maximum change in the parameter value per iter.
;     .TIED - e.g. : parinfo(2).tied = '2 * P(1)'.
;     .MPPRINT - if set to 1, then the default ITERPROC will print

; Since we are lumping all kinds of different parameters together,
; into one parameter list, we need to have some quick way of
; identifying and separating things out.  So let's define some
; additional fields in the parinfo structure (some integer, some
; floating point) that act as handles for the where() function.  There
; is intentionally some overlap between tags to make for easy
; referencing in a variety of circumstances.
;
;	.ssoID -- high-level parameter type identification.  These are
;                 meant to be independent of the actual functional
;                 forms used.  This tag should be set for each
;                 parameter that composes a function (i.e. for all 4
;                 Voigt parameters).
;		0 = not specified
;		1 = dispersion relation
;		2 = sensitivity function (response to white light source)
; 		3 = instrument profile (response to delta function)
;		4 = doppler shift (e.g. reflected solar or object)
;		5 = continuum
;		6 = line
;		negative = parameter not used (can be a tag for deletion)
;	.SSOftype -- function type identification, in generic terms.
;                    The idea is not to get too fancy here, just
;                    define a few basic types so the parameters can be
;                    grabbed easily by the primitives that implement
;                    these functions.  Each function will have a group
;                    of parameters associated with it (e.g. a Voigt
;                    has 4).  The specific use of the parameter is
;                    indicated by a decimal number, but is kept vague
;                    at this point.  For instance, the parameter
;                    "related to area" might end up being equivalent
;                    width, as determined by .ssounit.   "Related to
;                    line center" might be a delta wavelength from the
;                    expected value if .ssoowl is set.
;		0 = not an SSO parameter
;		1 = polynomial.  Let's try to make a generic
;		    definition for a polynomial function made up of
;		    segments.  The first segment starts at the [pixel]
;		    value labeled with 1.0 (0 if there is no 1.0) and
;		    the segments proceed to the right.  The
;		    polynomial coeficients are labeled 1.x0-1.x999,
;		    where x >= 1.  The boundary between segment 1.x
;		    and 1.(x+1) is labeled 1.0x.  If you need more
;		    than 9 segments, make another ftype.
;		  1.01-1.09 = 1st through 9th reference values
;		        (e.g. for dispersion, reference pixel for zero
;		        point of wavelength axis; for sensitivity
;		        function, first break point)
;		  1.10-1.1999 = 0-999th order polynomial coefficient
;		        of first polynomial
;		  1.20-1.2999 = 0-999th order polynomial coefficient
;		        of second polynomial
;		  1.30-1.n999 = etc.
;		2 = delta fn
;		  2.1 = related to line center
;		  2.2 = related to area
; 		3 = Gaussian
;		  3.1 = related to line center
;		  3.2 = related to area
;		  3.3 = related to width
; 		4 = Voigt
;		  4.1 = related to line center
;		  4.2 = related to area
;		  4.3 = related to Gaussian width
;		  4.4 = related to Lorentzian width
; 	.SSOunit -- The units of the parameter in question in a very
;                   generic sense.  This is sort of a bitmap, where
;                   multiplication of units means adding their tag
;                   values, and division means subtracting.  So a
;                   first-order dispersion coefficient will have a tag
;                   value of 2, corresponding to, e.g. A/pix.  So as
;                   not to be too confusing, polynomial coefs past 1st
;                   order have the same label as 1st order, since their
;                   actual units are easy to figure out at that point.
;                   This is mainly to get a handle on whether this is
;                   a pre- or post- dispersion relation function and
;                   whether or not the polynomial is scaled (scaling
;                   parameters all to approximately the same value
;                   makes them easier to display and makes mpfit
;                   behave better without having to fiddle with the
;                   .*step tags).
;		0 = units not specified
;		+/-1 = instrument coordinates (e.g. pixels)
;		+/-3 = converted coordinates (e.g. Angstroms, km/s,
;		       electrons/s) 
;		+/-10 = if for a polynomial coef, scaled by a factor
;		        of 10 per order (+100 would be scaled by a
;		        factor of 100)
;	.SSOsrc -- source of the feature.  This is a generic list
;                  arranged in increasing distance from the detector.
;                  Non-conflicting decimal subcategories should be
;                  added as necessary so that an encyclopedic line
;                  list can be kept organized.  This tag, together
;                  with ssorwl should be sufficient for determining
;                  the unique
;		0 = source not identified
;		1 = instrument
;		2 = telescope
;		3 = anthropogenic (e.g. city lights)
;		4 = terrestrial atmospheric
;		5 = zodiacal
;		6 = object
;		7 = reflected sunlight from object
;		8 = background light
;	.SSOltype -- line type.  This is a very simple taxonomy.
;		0 = not a line
;		<0 = absorption
;		>0 = emission
;		abs()+1 = atomic
;		abs()+2 = molecular
;		abs()+4 = narrow
;		abs()+8 = broad
;		abs()+16 = complex
;		abs()+32 = weak
;		abs()+64 = strong
;		abs()+128 = saturated
;	.SSOrwl -- rest wavelength of the line, or rather, the
;                  wavelength of the line when the source is viewed
;                  directly by an observer traveling at the same speed
;                  as the source (i.e. solar lines are
;                  relativistically shifted).  This, together with
;                  ssosrc is the handle by which lines can be uniquely
;                  identified.  Both tags should be set to the same
;                  values on all of the parameters that define a
;                  particular feature.
;	.SSOowl -- observed (i.e. Doppler shifted) wavelength.  If
;                  this tag is non-zero, the parameter it corresponds
;                  to is assumed to be the OFFSET from this value in
;                  the same units.
;	.SSOdop -- Doppler group.  For ease of handling, only set this
;                  for the line center or other appropriate parameter
;                  in the function.
;		0 = parameter not Doppler shiftable
;		1 = single Doppler shift (e.g. Io/object emission
;		    line)
;		2 = double Doppler shift (e.g. reflected sunlight)
;		>2 = other Doppler shift situation applies
;		     (e.g. multiple Galilean satellites in view,
;		     multiple IPM/ISM clouds at different velocities)
;	.SSOvalue -- best a priori estimate of parameter value
;	.SSOsID -- species name
;	.SSOion -- ionization state in spectroscopic notation
;		0 = unspecified
;		1 = neutral
;		2 = singly ionized, etc.
;	.SSOlID -- line identification.  I am not sure which, if any
;                  standard to adopt for this.
;	.SSOcomment -- comment, e.g. raw text of line/species ID from
;                      catalog 
;


; -

;; Until I make a library, 

defsysv, '!sso', exists=sso_exists
if sso_exists ne 1 then sso__define

.r sso_utils

;; pro sso_init
;;   defsysv, '!sso', exists=sso_exists
;;   if sso_exists ne 1 then $
;;     message, 'ERROR: you must issue the command @sso_init in your idl startup program'
;; 
;; end



