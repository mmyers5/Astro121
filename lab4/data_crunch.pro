FUNCTION gas_mass, delV, r, gLong
;+
; OVERVIEW
; --------
; will get the mass seen along telescope lines of sight for longitudes
; currently only works for 0<l<90 in two degree intervals
;
; CALLING SEQUENCE
; ----------------
; result = gas_mass(delV, r)
;
; PARAMETERS
; ----------
; delV: list
;     the velocity dispersion observed at various r's in km/s. be careful
;     interpreting results. depending on the velocity dispersion used, could be
;     including mass from areas outside the intended r
; r: list
;     galactocentric distances in kpc
;
; OUTPUTS
; -------
; gmass: list
;     the gas mass seen per provided longitude in kg. hint: sum-thing
;-
  l = findgen(45)*2*!dtor                         ; get 0<l<90 in radians
  d = 8.5*cos(l)*3.08567758d21                    ; get distance from sun in cm
  mH = 1.6605402d-24                              ; mass of hydrogen in g
  tA = 100.                                       ; brightness temp in K
  bwidth = 3*!dtor                                ; beam width in radians
  delVm *= 1.d5                                   ; velocities in cm/s
  gmass = 1.8d18*delVm*(d^2)*mH*tA*bwidth         ; get gmass in grams
  gmass /= 1.d3                                   ; get gmass in kilograms
  RETURN, gmass
END

FUNCTION mass_distrib, velo, r
;+
; OVERVIEW
; --------
; will plot a rough mass distribution curve for longitude 0<l<90
;
; CALLING SEQUENCE
; ----------------
; result=mass_distrib(velo,r)
;
; PARAMETERS
; ----------
; velo: list
;     the rotational velocities in km/s
; r: list
;     the galactocentric distances that correpond to the velocities in kpc
; 
; OUTPUTS
; -------
; distrib: struct
;     contains mass distribution info. tags are as follows:
;     r: the distance from galactic center in kpc
;     mass: the mass in Msun
;-
  velom = velo*1.d3                          ; velocities in m/s
  rm = r*(3.08567758d19)                     ; distances in meters
  mass = ((velom^2)*rm/(6.673d-11))/1.d3     ; calculate mass in kg                     
  mass /= 1.989d30                           ; get mass in Msun
  plot, r, mass, title='Mass Distribution Curve of Galaxy for 0<l<90',$
    xtitle='Distance from galactic center (kpc)',$
    ytitle='Gravitational Mass Enclosed (M_sun)', /xstyle, /ystyle, psym=-4
  distrib = {r:r, mass:mass}
  RETURN, distrib
END

FUNCTION rot_curve, maxVels, err=errVels
;+
; OVERVIEW
; --------
; will plot a rotation curve for longitude 0<l<90
;
; CALLING SEQUENCE
; ----------------
; result=rot_curve(maxVels, err=errVels)
;
; PARAMETERS
; ----------
; maxVels: list
;     the max doppler velocity recorded from observations, assumed to be for
;     0<l<90 at 2 degree spacings because why not!
; 
; KEYWORDS
; --------
; err: list
;     optional parameter. if grabbed guessed error for each maxvel, will be
;     included in plot and.  should be 2 x N, where row 0
;     is the lower bound of error and row 1 is upper bound
;
; OUTPUTS
; -------
; curve: struct
;     contains rotation curve info. tags are as follows:
;     r: the distance from galactic center in kpc
;     velo: the velocity that corresponds with r in km/s
;-
  rsun = 8.5                  ; distance of sun from GC in kpc
  vsun = 220                  ; circular velocity of sun in km/s
  l = (findgen(45)*2.+0.001)*!dtor    ; the longitudinal coordinates
  r = rsun*sin(l)             ; estimated distances for maxvels
  velo = ((maxVels/r)+(vsun/rsun))*r     ; equation chuggernaut
  plot, r, velo, title='Rotation Curve of Galaxy for 0<l<90',$
    xtitle='Distance from galactic center (kpc)',$
    ytitle='Rotational Velocity (km/s)', /xstyle, /ystyle, psym=-4
  IF keyword_set(errVels) THEN BEGIN
    lowErr = maxVels-errVels[*,0]        ; get lower errors
    highErr = maxVels+errVels[*,1]       ; get higher errors
    lowvelo = ((lowErr/r)+(vsun/rsun))*r ; get error results
    highvelo = ((highErr/r)+(vsun/rsun))*r
    print, lowvelo
    errplot, r, lowVelo, highVelo
  ENDIF 
  curve = {r:r, velo:velo}
  RETURN, curve
END
