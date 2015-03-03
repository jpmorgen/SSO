; +
; $Id: lc_sysvar__define.pro,v 1.3 2015/03/03 20:07:10 jpmorgen Exp $

; lc_sysvar__define.pro 

; This procedure makes use of the handy feature in IDL 5 that calls
; the procedure mystruct__define when mystruct is referenced.
; Unfortunately, if IDL calls this proceedure itself, it uses its own
; idea of what null values should be.  So call explicitly with an
; argument if you need to have a default structure with different
; initial values, or as in the case here, store the value in a system
; variable.

;; This defines the !lc system variable, which contains the
;; correspondences between catalog number and name, the ptype
;; parameter correspondences and the definition of the ltype taxonomy
;; and some other handy things.  Stick an initialized lc_struct record
;; on the end for handy reference.

;; Catalog numbers might be a bad idea: debated putting a cat_name tag
;; onto lc_struct.  As long as people mantain the tokens and cat_names
;; here, however, there is no need for it.  Since reading in catalogs
;; is catalog specific, they will be mucking with the code anyway, so
;; assume people will be good and modify this too....

;; Top is the top level of the directory in which data files are
;; stored

; -

pro lc_sysvar__define, top
  ;; System variables cannot be redefined and named structures cannot
  ;; be changed once they are defined, so it is OK to check this right
  ;; off the bat
  defsysv, '!lc', exists=exists
  if exists eq 1 then begin
     if keyword_set(top) then $
       !lc.top = top
     return
  endif
  
  if N_elements(top) eq 0 then $
    top = '/data/'

  ;; Use the JPL ephemerides numbers for sources
  init = {eph_sysvar}

  lc_struct__define, lc_struct=lc_struct
  lc $
    = {lc_sysvar, $
       c	: 299792458d, $ ;; m/s, double precision
       top	:	top, $
       name_format :	'a12', $ ;; Print format for line name
       $ ;; NRT/g for gas law calcs from PV=NRT and 1 atm = 760 mm
       $ ;; of Hg (molar weight = 13.59).
       NRTog	:	13.59d * 76.0d, $
       NA	:	6.0220978D23, $ ;; Avagadro's number
       $ ;; ADD TO THIS LIST!
       moore	:	1, $
       pb	:	2, $
       ap	:	3, $
       meylan	:	4, $
       huestis	:	5, $
       hitran	:	6, $
       kurucz	:	7, $
       sso	:	8, $
       cat_names:	['NONE', 'Moore', 'Pierce-Brekenridge', 'Allende Prieto & Garcia Lopez', 'Meylan', 'Huestis', 'HITRAN', 'kurucz', 'SSO'], $
       $ ;; ptype correspondences
       wavelength:	1, $	;; Standardize wavelengths to Angstroms
       wavelen	:	1, $
       wave	:	1, $
       center	:	1, $
       equiv_width:	2, $	;; Standardize all widths to milliAngstroms
       eq_w	:	2, $
       ew	:	2, $
       eqw	:	2, $
$;       area	:	2, $
       gwidth	:	3, $	;; Gaussian and Lorentzian width tokens
       gw	:	3, $
       lwidth	:	4, $
       lw	:	4, $
       $ ;; ltype tokens: a simple taxonomy of lines
       line	:	ishft(1,0),   $
       emiss	:	ishft(1,1),   $
       absorp	:	ishft(1,2),   $
       atomic	:	ishft(1,3),   $
       molec	:	ishft(1,4),   $
       narrow	:	ishft(1,5),   $
       broad	:	ishft(1,6),   $
       complex	:	ishft(1,7),   $
       weak	:	ishft(1,8),   $
       strong	:	ishft(1,9),   $
       sat	:	ishft(1,10),  $
       $ ;; quality tokens
       none	:	0, $
       best	:	1, $
       good	:	2, $
       OK	:	3, $
       bad	:	4, $
       useless	:	5, $
       $ ;; Store READ_ASCII versions of catalogs in heap variables for 
       $ ;; quick access 
       cats	:	ptr_new(),    $
       amasses	:	dblarr(110), $
       asymbols	:	strarr(110), $
       anames	:	strarr(110), $
       $ ;; Tack on an initialize lc_struct
       lc_struct:	lc_struct}
  
  defsysv, '!lc', lc

  ;; Got list from:
  ;; http://environmentalchemistry.com/yogi/periodic/mass.html
  !lc.amasses[1  ] = 1.00794	
  !lc.amasses[2  ] = 4.002602	
  !lc.amasses[3  ] = 6.941	
  !lc.amasses[4  ] = 9.012182	
  !lc.amasses[5  ] = 10.811	
  !lc.amasses[6  ] = 12.011	
  !lc.amasses[7  ] = 14.00674	
  !lc.amasses[8  ] = 15.9994	
  !lc.amasses[9  ] = 18.9984	
  !lc.amasses[10 ] = 20.1797	
  !lc.amasses[11 ] = 22.98977	
  !lc.amasses[12 ] = 24.305	
  !lc.amasses[13 ] = 26.98154	
  !lc.amasses[14 ] = 28.0855	
  !lc.amasses[15 ] = 30.97376	
  !lc.amasses[16 ] = 32.066	
  !lc.amasses[17 ] = 35.4527	
  !lc.amasses[19 ] = 39.0983	
  !lc.amasses[18 ] = 39.948	
  !lc.amasses[20 ] = 40.078	
  !lc.amasses[21 ] = 44.95591	
  !lc.amasses[22 ] = 47.88	
  !lc.amasses[23 ] = 50.9415	
  !lc.amasses[24 ] = 51.9961	
  !lc.amasses[25 ] = 54.93805	
  !lc.amasses[26 ] = 55.847	
  !lc.amasses[28 ] = 58.6934	
  !lc.amasses[27 ] = 58.9332	
  !lc.amasses[29 ] = 63.546	
  !lc.amasses[30 ] = 65.39	
  !lc.amasses[31 ] = 69.723	
  !lc.amasses[32 ] = 72.61	
  !lc.amasses[33 ] = 74.92159	
  !lc.amasses[34 ] = 78.96	
  !lc.amasses[35 ] = 79.904	
  !lc.amasses[36 ] = 83.8	
  !lc.amasses[37 ] = 85.4678	
  !lc.amasses[38 ] = 87.62	
  !lc.amasses[39 ] = 88.90585	
  !lc.amasses[40 ] = 91.224	
  !lc.amasses[41 ] = 92.90638	
  !lc.amasses[42 ] = 95.94	
  !lc.amasses[43 ] = 98		
  !lc.amasses[44 ] = 101.07	
  !lc.amasses[45 ] = 102.9055	
  !lc.amasses[46 ] = 106.42	
  !lc.amasses[47 ] = 107.8682	
  !lc.amasses[48 ] = 112.411	
  !lc.amasses[49 ] = 114.82	
  !lc.amasses[50 ] = 118.71	
  !lc.amasses[51 ] = 121.757	
  !lc.amasses[53 ] = 126.9045	
  !lc.amasses[52 ] = 127.6	
  !lc.amasses[54 ] = 131.29	
  !lc.amasses[55 ] = 132.9054	
  !lc.amasses[56 ] = 137.327	
  !lc.amasses[57 ] = 138.9055	
  !lc.amasses[58 ] = 140.115	
  !lc.amasses[59 ] = 140.9077	
  !lc.amasses[60 ] = 144.24	
  !lc.amasses[61 ] = 145	
  !lc.amasses[62 ] = 150.36	
  !lc.amasses[63 ] = 151.965	
  !lc.amasses[64 ] = 157.25	
  !lc.amasses[65 ] = 158.9253	
  !lc.amasses[66 ] = 162.5	
  !lc.amasses[67 ] = 164.9303	
  !lc.amasses[68 ] = 167.26	
  !lc.amasses[69 ] = 168.9342	
  !lc.amasses[70 ] = 173.04	
  !lc.amasses[71 ] = 174.967	
  !lc.amasses[72 ] = 178.49	
  !lc.amasses[73 ] = 180.9479	
  !lc.amasses[74 ] = 183.85	
  !lc.amasses[75 ] = 186.207	
  !lc.amasses[76 ] = 190.2	
  !lc.amasses[77 ] = 192.22	
  !lc.amasses[78 ] = 195.08	
  !lc.amasses[79 ] = 196.9665	
  !lc.amasses[80 ] = 200.59	
  !lc.amasses[81 ] = 204.3833	
  !lc.amasses[82 ] = 207.2	
  !lc.amasses[83 ] = 208.9804	
  !lc.amasses[84 ] = 209	
  !lc.amasses[85 ] = 210	
  !lc.amasses[91 ] = 213.0359	
  !lc.amasses[86 ] = 222	
  !lc.amasses[87 ] = 223	
  !lc.amasses[88 ] = 226.0254	
  !lc.amasses[89 ] = 227	
  !lc.amasses[90 ] = 232.0381	
  !lc.amasses[93 ] = 237.0482	
  !lc.amasses[92 ] = 238.0289	
  !lc.amasses[95 ] = 243	
  !lc.amasses[94 ] = 244	
  !lc.amasses[96 ] = 247	
  !lc.amasses[97 ] = 247	
  !lc.amasses[98 ] = 251	
  !lc.amasses[99 ] = 252	
  !lc.amasses[100] = 257	
  !lc.amasses[101] = 258	
  !lc.amasses[102] = 259	
  !lc.amasses[103] = 260	
  !lc.amasses[104] = 261	
  !lc.amasses[105] = 262	
  !lc.amasses[107] = 262	
  !lc.amasses[106] = 263	
  !lc.amasses[108] = 265	
  !lc.amasses[109] = 266	

  !lc.asymbols[1  ] = 'H '
  !lc.asymbols[2  ] = 'He'
  !lc.asymbols[3  ] = 'Li'
  !lc.asymbols[4  ] = 'Be'
  !lc.asymbols[5  ] = 'B '
  !lc.asymbols[6  ] = 'C '
  !lc.asymbols[7  ] = 'N '
  !lc.asymbols[8  ] = 'O '
  !lc.asymbols[9  ] = 'F '
  !lc.asymbols[10 ] = 'Ne'
  !lc.asymbols[11 ] = 'Na'
  !lc.asymbols[12 ] = 'Mg'
  !lc.asymbols[13 ] = 'Al'
  !lc.asymbols[14 ] = 'Si'
  !lc.asymbols[15 ] = 'P '
  !lc.asymbols[16 ] = 'S '
  !lc.asymbols[17 ] = 'Cl'
  !lc.asymbols[19 ] = 'K '
  !lc.asymbols[18 ] = 'Ar'
  !lc.asymbols[20 ] = 'Ca'
  !lc.asymbols[21 ] = 'Sc'
  !lc.asymbols[22 ] = 'Ti'
  !lc.asymbols[23 ] = 'V '
  !lc.asymbols[24 ] = 'Cr'
  !lc.asymbols[25 ] = 'Mn'
  !lc.asymbols[26 ] = 'Fe'
  !lc.asymbols[28 ] = 'Ni'
  !lc.asymbols[27 ] = 'Co'
  !lc.asymbols[29 ] = 'Cu'
  !lc.asymbols[30 ] = 'Zn'
  !lc.asymbols[31 ] = 'Ga'
  !lc.asymbols[32 ] = 'Ge'
  !lc.asymbols[33 ] = 'As'
  !lc.asymbols[34 ] = 'Se'
  !lc.asymbols[35 ] = 'Br'
  !lc.asymbols[36 ] = 'Kr'
  !lc.asymbols[37 ] = 'Rb'
  !lc.asymbols[38 ] = 'Sr'
  !lc.asymbols[39 ] = 'Y '
  !lc.asymbols[40 ] = 'Zr'
  !lc.asymbols[41 ] = 'Nb'
  !lc.asymbols[42 ] = 'Mo'
  !lc.asymbols[43 ] = 'Tc'
  !lc.asymbols[44 ] = 'Ru'
  !lc.asymbols[45 ] = 'Rh'
  !lc.asymbols[46 ] = 'Pd'
  !lc.asymbols[47 ] = 'Ag'
  !lc.asymbols[48 ] = 'Cd'
  !lc.asymbols[49 ] = 'In'
  !lc.asymbols[50 ] = 'Sn'
  !lc.asymbols[51 ] = 'Sb'
  !lc.asymbols[53 ] = 'I '
  !lc.asymbols[52 ] = 'Te'
  !lc.asymbols[54 ] = 'Xe'
  !lc.asymbols[55 ] = 'Cs'
  !lc.asymbols[56 ] = 'Ba'
  !lc.asymbols[57 ] = 'La'
  !lc.asymbols[58 ] = 'Ce'
  !lc.asymbols[59 ] = 'Pr'
  !lc.asymbols[60 ] = 'Nd'
  !lc.asymbols[61 ] = 'Pm'
  !lc.asymbols[62 ] = 'Sm'
  !lc.asymbols[63 ] = 'Eu'
  !lc.asymbols[64 ] = 'Gd'
  !lc.asymbols[65 ] = 'Tb'
  !lc.asymbols[66 ] = 'Dy'
  !lc.asymbols[67 ] = 'Ho'
  !lc.asymbols[68 ] = 'Er'
  !lc.asymbols[69 ] = 'Tm'
  !lc.asymbols[70 ] = 'Yb'
  !lc.asymbols[71 ] = 'Lu'
  !lc.asymbols[72 ] = 'Hf'
  !lc.asymbols[73 ] = 'Ta'
  !lc.asymbols[74 ] = 'W '
  !lc.asymbols[75 ] = 'Re'
  !lc.asymbols[76 ] = 'Os'
  !lc.asymbols[77 ] = 'Ir'
  !lc.asymbols[78 ] = 'Pt'
  !lc.asymbols[79 ] = 'Au'
  !lc.asymbols[80 ] = 'Hg'
  !lc.asymbols[81 ] = 'Tl'
  !lc.asymbols[82 ] = 'Pb'
  !lc.asymbols[83 ] = 'Bi'
  !lc.asymbols[84 ] = 'Po'
  !lc.asymbols[85 ] = 'At'
  !lc.asymbols[91 ] = 'Pa'
  !lc.asymbols[86 ] = 'Rn'
  !lc.asymbols[87 ] = 'Fr'
  !lc.asymbols[88 ] = 'Ra'
  !lc.asymbols[89 ] = 'Ac'
  !lc.asymbols[90 ] = 'Th'
  !lc.asymbols[93 ] = 'Np'
  !lc.asymbols[92 ] = 'U '
  !lc.asymbols[95 ] = 'Am'
  !lc.asymbols[94 ] = 'Pu'
  !lc.asymbols[96 ] = 'Cm'
  !lc.asymbols[97 ] = 'Bk'
  !lc.asymbols[98 ] = 'Cf'
  !lc.asymbols[99 ] = 'Es'
  !lc.asymbols[100] = 'Fm'
  !lc.asymbols[101] = 'Md'
  !lc.asymbols[102] = 'No'
  !lc.asymbols[103] = 'Lr'
  !lc.asymbols[104] = 'Rf'
  !lc.asymbols[105] = 'Db'
  !lc.asymbols[107] = 'Bh'
  !lc.asymbols[106] = 'Sg'
  !lc.asymbols[108] = 'Hs'
  !lc.asymbols[109] = 'Mt'

  !lc.asymbols = strtrim(!lc.asymbols,2)

  !lc.anames[1  ] = 'Hydrogen	'
  !lc.anames[2  ] = 'Helium	'
  !lc.anames[3  ] = 'Lithium	'
  !lc.anames[4  ] = 'Beryllium	'
  !lc.anames[5  ] = 'Boron	'
  !lc.anames[6  ] = 'Carbon	'
  !lc.anames[7  ] = 'Nitrogen	'
  !lc.anames[8  ] = 'Oxygen	'
  !lc.anames[9  ] = 'Fluorine	'
  !lc.anames[10 ] = 'Neon	'
  !lc.anames[11 ] = 'Sodium	'
  !lc.anames[12 ] = 'Magnesium	'
  !lc.anames[13 ] = 'Aluminum	'
  !lc.anames[14 ] = 'Silicon	'
  !lc.anames[15 ] = 'Phosphorus	'
  !lc.anames[16 ] = 'Sulfur	'
  !lc.anames[17 ] = 'Chlorine	'
  !lc.anames[19 ] = 'Potassium	'
  !lc.anames[18 ] = 'Argon	'
  !lc.anames[20 ] = 'Calcium	'
  !lc.anames[21 ] = 'Scandium	'
  !lc.anames[22 ] = 'Titanium	'
  !lc.anames[23 ] = 'Vanadium	'
  !lc.anames[24 ] = 'Chromium	'
  !lc.anames[25 ] = 'Manganese	'
  !lc.anames[26 ] = 'Iron	'
  !lc.anames[28 ] = 'Nickel	'
  !lc.anames[27 ] = 'Cobalt	'
  !lc.anames[29 ] = 'Copper	'
  !lc.anames[30 ] = 'Zinc	'
  !lc.anames[31 ] = 'Gallium	'
  !lc.anames[32 ] = 'Germanium	'
  !lc.anames[33 ] = 'Arsenic	'
  !lc.anames[34 ] = 'Selenium	'
  !lc.anames[35 ] = 'Bromine	'
  !lc.anames[36 ] = 'Krypton	'
  !lc.anames[37 ] = 'Rubidium	'
  !lc.anames[38 ] = 'Strontium	'
  !lc.anames[39 ] = 'Yttrium	'
  !lc.anames[40 ] = 'Zirconium	'
  !lc.anames[41 ] = 'Niobium	'
  !lc.anames[42 ] = 'Molybdenum	'
  !lc.anames[43 ] = 'Technetium	'
  !lc.anames[44 ] = 'Ruthenium	'
  !lc.anames[45 ] = 'Rhodium	'
  !lc.anames[46 ] = 'Palladium	'
  !lc.anames[47 ] = 'Silver	'
  !lc.anames[48 ] = 'Cadmium	'
  !lc.anames[49 ] = 'Indium	'
  !lc.anames[50 ] = 'Tin	'
  !lc.anames[51 ] = 'Antimony	'
  !lc.anames[53 ] = 'Iodine	'
  !lc.anames[52 ] = 'Tellurium	'
  !lc.anames[54 ] = 'Xenon	'
  !lc.anames[55 ] = 'Cesium	'
  !lc.anames[56 ] = 'Barium	'
  !lc.anames[57 ] = 'Lanthanum	'
  !lc.anames[58 ] = 'Cerium	'
  !lc.anames[59 ] = 'Praseodymium'
  !lc.anames[60 ] = 'Neodymium	'
  !lc.anames[61 ] = 'Promethium	'
  !lc.anames[62 ] = 'Samarium	'
  !lc.anames[63 ] = 'Europium	'
  !lc.anames[64 ] = 'Gadolinium	'
  !lc.anames[65 ] = 'Terbium	'
  !lc.anames[66 ] = 'Dysprosium	'
  !lc.anames[67 ] = 'Holmium	'
  !lc.anames[68 ] = 'Erbium	'
  !lc.anames[69 ] = 'Thulium	'
  !lc.anames[70 ] = 'Ytterbium	'
  !lc.anames[71 ] = 'Lutetium	'
  !lc.anames[72 ] = 'Hafnium	'
  !lc.anames[73 ] = 'Tantalum	'
  !lc.anames[74 ] = 'Tungsten	'
  !lc.anames[75 ] = 'Rhenium	'
  !lc.anames[76 ] = 'Osmium	'
  !lc.anames[77 ] = 'Iridium	'
  !lc.anames[78 ] = 'Platinum	'
  !lc.anames[79 ] = 'Gold	'
  !lc.anames[80 ] = 'Mercury	'
  !lc.anames[81 ] = 'Thallium	'
  !lc.anames[82 ] = 'Lead	'
  !lc.anames[83 ] = 'Bismuth	'
  !lc.anames[84 ] = 'Polonium	'
  !lc.anames[85 ] = 'Astatine	'
  !lc.anames[91 ] = 'Protactinium'
  !lc.anames[86 ] = 'Radon	'
  !lc.anames[87 ] = 'Francium	'
  !lc.anames[88 ] = 'Radium	'
  !lc.anames[89 ] = 'Actinium	'
  !lc.anames[90 ] = 'Thorium	'
  !lc.anames[93 ] = 'Neptunium	'
  !lc.anames[92 ] = 'Uranium	'
  !lc.anames[95 ] = 'Americium	'
  !lc.anames[94 ] = 'Plutonium	'
  !lc.anames[96 ] = 'Curium	'
  !lc.anames[97 ] = 'Berkelium	'
  !lc.anames[98 ] = 'Californium'
  !lc.anames[99 ] = 'Einsteinium'
  !lc.anames[100] = 'Fermium	'
  !lc.anames[101] = 'Mendelevium'
  !lc.anames[102] = 'Nobelium	'
  !lc.anames[103] = 'Lawrencium	'
  !lc.anames[104] = 'Rutherfordium'
  !lc.anames[105] = 'Dubnium	'
  !lc.anames[107] = 'Bohrium	'
  !lc.anames[106] = 'Seaborgium	'
  !lc.anames[108] = 'Hassium	'
  !lc.anames[109] = 'Meitnerium	'

  !lc.anames = strtrim(!lc.anames,2)

end
