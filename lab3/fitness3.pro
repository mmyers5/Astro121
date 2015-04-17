FUNCTION brute_force, dec, locFreq, hAngles, RHS, count
;+
; OVERVIEW
; --------
; will do a brute force least-squares fitting to get declination of a
; stellar object
;
; CALLING SEQUENCE
; ----------------
; result=brute_force(dec, locFreq, hAngles, RHS, count)
;
; PARAMETERS
; ----------
; dec: float
;     the first guess you would like to adopt for the
;     declination in radians. after every iteration specified by
;     count, dec will be increased by 0.001
; locFreq: float
;     the frequency at which you made the observation in Hz
; hAngles: list
;     the hour angles of the stellar body upon observation
; RHS: list
;     the array for the voltage amplitude, i.e. str.volts
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
  M = n_elements(RHS)                       ; the number of measurements
  N = 2.                                     ; the number of unknowns
  sumSquares = 100                          ; sufficiently large sum of squares
  sumSquaresArr = []                        ; array to hold sum_squares
  CArr = []                                 ; array to hold C
  FOR i = 0, count DO BEGIN
    C = 2.*!pi*(15./lambda) * cos(dec)             ; compute C
    arg = C * sin(hAngles)       ; complete the argument
    LHS = [ [cos(arg)], [-sin(arg)] ]       ; start left-hand-side
    LHS = transpose(LHS)
    alpha = transpose(LHS)##LHS             ; see least squares lite handout
    beta = transpose(LHS)##RHS
    coeffs = invert(alpha)##beta            ; the coefficients, A and B
    fittedRHS = LHS ## coeffs               ; get fitted RHS
    resids = RHS - fittedRHS                ; residuals in RHS
    sumSquaresPrime = total(resids^2)/(M-N) ; get sum of squares
    CArr = [CArr, C]
    sumSquaresArr = [sumSquaresArr,sumSquaresPrime]
    IF sumSquaresPrime LT sumSquares THEN BEGIN
      fittedDec = acos(C*(lambda/15d)/(2.*!pi)) ; get declination from C
      fitted={A:coeffs[0],$                   ; A coefficient
              B:coeffs[1],$                   ; B coefficient
              std:sumSquaresPrime,$           ; sum of squares
              dec:fittedDec}                  ; declination
    ENDIF
	dec += 0.001                            ; increment declination by 0.1
  ENDFOR
	decArr = acos(Carr*(lambda/15d)/(2.*!pi))
	sumSquaresArr /= mean(sumSquaresArr)
	plot, decArr, sumSquaresArr, /xstyle, /ystyle,$
	title='Brute Force Least-Squares Fit for w51a',$
	xtitle='Declination (rad)', ytitle='Sum of Squares'
	return, fitted
END
