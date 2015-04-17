PRO brute_force, dec, locFreq, hAngles, RHS, count, fitted
;+
; OVERVIEW
; --------
; will do a brute force least-squares fitting to get declination of a
; stellar object
;
; CALLING SEQUENCE
; ----------------
; pro brute_force, dec, locFreq, hAngles, RHS, count, fitted
;
; PARAMETERS
; ----------
; dec: float
;     the first guess you would like to adopt for the declination
;     after every iteration specified by count, dec will be increased by 0.1
; locFreq: float
;     the frequency at which you made the observation in Hz
; hAngles: list
;     the hour angles of the stellar body upon observation
; RHS: list
;     the file for the voltage amplitude, i.e. str.volts
; count: int
;     the number of times you would like the function to be
;     evaluated. the more the merrier
; 
; OUTPUTS
; -------
; fitted: struct
;     a structure containing the fitted values that correspond to the
;     smallest sum of least-squares. tags are as follows:
;     {A, B, C, std, dec}
;-
  lambda = 3d8/locFreq                      ; get the wavelength
  M = double(n_elements(RHS))               ; the number of measurements
  N = 2d                                    ; the number of unknowns
  CArr = []
  sumSquaresArr = []
  AArr = []
  BArr = []
  FOR i = 0, count DO BEGIN
    C = (10d/lambda) * cos(dec)             ; get the argument of trig functions
    arg = 2d * !pi * C * sin(hAngles)       ; complete the argument
    LHS = [ [cos(arg)], [-sin(arg)] ]       ; start left-hand-side
    LHS = transpose(LHS)                    ; turn into proper matrix
    alpha = transpose(LHS)##LHS             ; see least squares lite handout
    beta = transpose(LHS)##RHS
    coeffs = invert(alpha)##beta            ; the coefficients, A and B
    AArr = [AArr, coeffs[0]]
    BArr = [BArr, coeffs[1]]
    fittedRHS = LHS ## coeffs               ; get fitted RHS
    resids = RHS - fittedRHS                ; residuals in RHS
    sumSquares = total(resids^2)/(M-N)      ; get sum of squares 
    CArr = [Carr, C]
    sumSquaresArr = [sumSquaresArr, sumSquares]
    dec += 0.001                             ; increment declination by 0.1
  ENDFOR
  decArr = acos(CArr*(lambda/10d))
  fitted = {A:AArr, B:Barr, C:Carr, std:sumSquaresArr, dec: decArr}
  ;fitted = [ [decArr], [sumSquaresArr] ]
END

FUNCTION hour_angle, ra, dec, LST
;+ 
; OVERVIEW
; --------
; will calculate the hour angles associated with the LST of an observation 
; and a given right ascension
; 
; CALLING SEQUENCE
; ----------------
; result = hour_angle(ra, dec, LST)
;
; PARAMETERS
; ----------
; ra: float
;     the right ascension of the point source in equinox 2000
;     and given in radians
; dec: float
;     the declination of the point source in equinox 2000
;     and given in radians
; LST: list
;     the LST of observation, i.e. str.LST
;
; OUTPUTS
; -------
; hAngles: list
;     the hour angles of the point source at observation
;-
  precess, ra, dec, 2000, 2015, /radian
  raDec = [ [cos(dec)*cos(ra)],$    ; get (ra,dec) in spherical coords
	    [cos(dec)*sin(ra)],$
	    [        sin(dec)] ]
  hAngles = []
  FOR i = 0, n_elements(LST)-1 DO BEGIN
    ha = raDec_haDec(raDec, LST[i]) ; evaluate ha for each LST
    hAngles = [hAngles, ha]         ; add to hAngles array
  ENDFOR
  return, hAngles
END

FUNCTION raDec_haDec, raDec, LST
;+ 
; OVERVIEW
; --------
; will perform matrix operations to rotate (ra,dec)->(ha,dec)
;
; CALLING SEQUENCE
; ----------------
; result = raDec_haDec(raDec, LST)
; 
; PARAMETERS
; ----------
; raDec: list
;      the (ra,dec) tuple in spherical coordinates
; LST: float
;      the local sidereal time to be evaluated at
;
; OUTPUTS
; -------
; ha: float
;     the hour angle of operations
;-
;
  raDec_haDec = [ [ cos(LST), sin(LST), 0],$ ; transformation matrix (ra,dec)->(ha,dec)
	          [-sin(LST), cos(LST), 0],$
		  [        0,        0, 1] ]
  haDec = raDec_haDec ## raDec
  ha = atan(haDec[1],haDec[0])
  return, ha
END
