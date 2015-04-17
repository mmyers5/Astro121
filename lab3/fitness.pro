PRO main_fit, guesses, D, hAngle, fitted
;+
; OVERVIEW
; --------
; will loop through the procedure that likes to perform non-linear 
; least squares stuff. will plot stuff to let you know when you
; can stop
;
; CALLING SEQUENCE
; ----------------
; main_fit, guesses, D, hAngle, fitted
;
; PARAMETERS
; ----------
; guesses: struct
;     a structure containing your guesses for the parameters, contains
;     the tags A, B, C
;     A, B, and C are the parameters referenced in the handout
; D: list
;     the data array from the observation, a.k.a. str.volts
; hAngle: list
;     the hour angles that correspond with the observation data
;
; OUTPUTS
; -------
; fitted: struct
;     structure with fitted tags. see doc for matrix_eval below
;     fitted.Dbar is altered to reflect D as opposed to D-Dg
;-

  test_your_might, guesses, D, hAngle, fitted       ; fit for the first time
  i = 0                                             ; initiate test counter
  WHILE i LT 100 DO BEGIN                             
    i += 1                  
    guesses = { A:fitted.A, B:fitted.B, C:fitted.C } ; grab new guess vals
    test_your_might, guesses, D, hAngle, fitted      ; evaluate at new guess vals    
  ENDWHILE
END

PRO test_your_might, guesses, D, hAngle, fitted
;+
; OVERVIEW
; --------
; will perform non-linear least squares fit
;
; CALLING SEQUENCE
; ----------------
; test_your_might, guesses, D, hAngle, fitted
;
; PARAMETERS
; ----------
; guesses: struct
;     a structure containing your guesses for the parameters, contains
;     the tags A, B, C
;     A, B, and C are the parameters referenced in the handout
; D: list
;     the data array from the observation, a.k.a. str.volts
; hAngle: list
;     the hour angles that correspond with the data
;
; OUTPUTS
; -------
; fitted: struct
;     structure with fitted data. see doc for matrix_eval below
;     fitted.dBar is altered to reflect D as opposed to D-Dg
;-
  Dg = fringe_func(guesses, hAngle)          ; evaluate function at guessed values
  RHS = D-Dg                                 ; get the right hand side of matrix
  ; evaluate derivatives and get left hand side
  dbl = 10d-5                                ; to form delA ~ Ad-5
  del = {A:guesses.A*dbl, B:guesses.B*dbl, C:guesses.C*dbl}  ; get delta structure
  LHS = deriv_eval(guesses, hAngle, del)     ; evaluation of derivatives
  ; evaluate matrix to get predicted values of delta coefficients
  fitted = matrix_eval(LHS, RHS)
  fitted.dBar+=Dg              ; get D-Dg+Dg
  fitted.A+=guesses.A          ; get new guess values
  fitted.B+=guesses.B          ; fitted vals + delta vals
  fitted.C+=guesses.C
END

FUNCTION matrix_eval, LHS, RHS
;+
; OVERVIEW
; --------
; will perform matrix operations to get coefficients of a thing
; see least squares lite handout for a definition of alpha and beta
;
; CALLING SEQUENCE
; ----------------
; result = matrix_eval(LHS, RHS)
;
; PARAMETERS
; ----------
; LHS: list
;     the left hand side of the matrix equation
; RHS: list
;     the right hand side of the matrix equation
;
; OUTPUTS
; -------
; fitted: struct
;     a structure containing all of the results of the matrix operations
;     tags are A, B, C, dBar, resids, errA, errB, errC
;-
  M = N_ELEMENTS(RHS)           ; get number of data points
  N = (size(LHS))[1]            ; get number of unknowns
  alpha = transpose(LHS) ## LHS
  beta = transpose(LHS) ## RHS
  alphaI = invert(alpha)
  coeffs = alphaI ## beta       ; the fitted coeffs
  dBar = LHS ## coeffs          ; predicted results from using fitted coeffs
  resids = RHS - dBar           ; residuals in predicted results
  stD = transpose(resids)##(resids)/(M-N)   ; square of standard deviation
  coeffsD = alphaI*[(N+1) * indgen(N)]      ; error in derived coeffs
  varDC = stD * coeffs                      ; variance in derived coeffs

  fitted = { A:coeffs[0], B:coeffs[1], C:coeffs[2], dBar:dBar, resids:resids, $
             errA:coeffsD[0], errB:coeffsD[1], errC:coeffsD[2] }
  RETURN, fitted
END

FUNCTION deriv_eval, guesses, hAngle, del
;+
; OVERVIEW
; --------
; will evaluate the parameter derived functions needed for the left hand
; side of matric
;
; CALLING SEQUENCE
; ----------------
; result = deriv_eval(guesses, hAngle, del)
; 
; PARAMETERS
; ----------
; guesses: struct
;     a structure containing your guesses for the parameters, contains
;     the tags A, B, C
;     A, B, and C are the parameters referenced in the handout
; hAngle: list
;     the hour angles array that correspond with julian days of observation
; del: struct
;     a structure containing your desired delta for the derivative,
;     contains the tags A, B, C
; 
; OUTPUTS
; -------
; LHS: list
;     the left hand side of the matrix, i.e. the derivatives of the
;     fringe function with respect to their parameters evaluated at
;     guess values plus a delta. 
;     each row corresponds to a new data point. each column corresponds
;     to a new parameter
;-
  ; generate structures that have each parameter altered
  structA = {A:guesses.A+del.A, B:guesses.B, C:guesses.C}
  structB = {A:guesses.A, B:guesses.B+del.B, C:guesses.C}
  structC = {A:guesses.A, B:guesses.B, C:guesses.C+del.C}
  ; evaluate functions with each parameter uniquely altered
  plusA = fringe_func(structA, hAngle)
  plusB = fringe_func(structB, hAngle)
  plusC = fringe_func(structC, hAngle)
  ; generate structures that have each parameter altered again
  structA = {A:guesses.A-del.A, B:guesses.B, C:guesses.C}
  structB = {A:guesses.A, B:guesses.B-del.B, C:guesses.C}
  structC = {A:guesses.A, B:guesses.B, C:guesses.C-del.C}
  ; evaluate functions with each parameter uniquely altered again
  minusA = fringe_func(structA, hAngle)
  minusB = fringe_func(structB, hAngle)
  minusC = fringe_func(structC, hAngle)
  ; evaluate averages of derivatives
  A = (plusA - minusA)/(2d*del.A)
  B = (plusB - minusB)/(2d*del.B)
  C = (plusC - minusC)/(2d*del.C)
  ; put it all together into a matrix
  LHS = transpose([ [A],[B],[C] ])
  RETURN, LHS
END

FUNCTION fringe_func, coeffs, H
;+
; OVERVIEW
; --------
; generates function 10 from the lab handout, evaluated at specified
; coefficients
;
; CALLING SEQUENCE
; ----------------
; result = fringe_func(coeffs)
;
; PARAMETERS
; ----------
; coeffs: struct
;     a structure containing the parameters for this particular lab,
;     which contain the tags A, B, C
;     A, B, and C are the parameters we are using in the handout.
;
; H: list
;     the hour angle of the source that we would like to use
;
; OUTPUTS
; -------
; daFunc: float
;     a single value of the function evaluated with A, B, C, and H.
;-
  argument = 2d*!pi*coeffs.C*sin(H)
  argument = !pi/2d
  daFunc = [coeffs.A*cos(argument)] - [coeffs.B*sin(argument)]
  RETURN, daFunc
END

FUNCTION hour_angle, ra, dec, jDay, sun=sunobs, moon=moonobs
;+
; OVERVIEW
; --------
; will get the hour angles at which an object was observed for specific
; times as well as the declinations
;
; CALLING SEQUENCE
; ----------------
; result = hour_angle(ra, dec, jDay, /sun)
;
; PARAMETERS
; ----------
; ra: float
;     the right ascension of the object on the julian days, in 2000 equinox 
; dec: float
;     the declination of the object on the julian days, in 2000 equinox
; jDay: list
;     the jDay list from the structure provided by startchart1
;
; KEYWORDS
; --------
; sun: byte
;     if sunobs is set with sun=some_value or /sun, then function will
;     ignore the ra and dec and proceed calculating ra and dec for the
;     sun on its own
;
; OUTPUTS
; -------
; haDec: list
;     the hour angles of the object for the specific julian days given
;     as well as the declinations
;-
  precess, ra, dec, 2000, 2015, /radian ; precess coordinates
  hAngle = []
  decAngle = []
  FOR i=0, N_ELEMENTS(jDay)-1 DO BEGIN
     IF KEYWORD_SET(sunobs) THEN BEGIN
        isun, ra, dec, juldate=jDay[i]     ; get (ra,dec) from isun
        ra = ra*15d*!dtor                  ; get ra in radians
        dec = dec*!dtor*1d                 ; get dec in radians
     ENDIF
     IF KEYWORD_SET(moonobs) THEN BEGIN
	imoon, ra, dec, juldate=jDay[i]
 	ra = ra*15d*!dtor
        dec = dec*!dtor*1d
     ENDIF
     LST = ilst(juldate=jDay[i])*15d*!dtor ; get local sidereal time in radians
     raDec = [ [cos(dec)*cos(ra)],$        ; vector (ra,dec)
               [cos(dec)*sin(ra)],$
               [        sin(dec)] ]
     raDec_haDec = [ [cos(LST),  sin(LST), 0],$ ; (ra,dec)->(ha,dec)
                     [sin(LST), -cos(LST), 0],$
                     [       0,         0, 1] ]
     haDec = raDec_haDec ## raDec     ; rotate (ra,dec)->(ha,dec) 
     ha = atan(haDec[1],haDec[0])     ; get hour angle in radians
     hAngle = [hAngle, ha]            ; append to hAngle array
     decAngle = [decAngle, dec]       ; append to decAngle array
  ENDFOR
  haDec = [[hAngle],[decAngle]]       ; make 2d array for (ha,dec)
                                      ; row 1 = ha, row 2 = dec
  RETURN, haDec
END
