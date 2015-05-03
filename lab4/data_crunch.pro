FUNCTION rot_curve, maxVels, err=errVels
;+
; OVERVIEW
; --------
; will plot a rotation curve for longitude 0<l<90
;
; CALLING SEQUENCE
; ----------------
; result=rot_curve(maxVels)
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
;     velo: the velocity that corresponds with r
;-
  rsun = 8.5                  ; distance of sun from GC in kpc
  vsun = 220                  ; circular velocity of sun in km/s
  l = findgen(45)*2.*!dtor    ; the longitudinal coordinates
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
