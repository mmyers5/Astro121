PRO diam_plots, frFreq, R, N, zeroPoints
;+
; OVERVIEW
; --------
; will plot the observed and theoretical modulating functions
; 
; CALLING SEQUENCE
; ----------------
; diam_plot, frFreq, R, N
;
; PARAMETERS
; ----------
; frFreq: float
;     the local fringe frequency of the source in cycles/radian
; R: list
;     test radius values in meters
; N: int
;     the number of data points in original data
;
; OUTPUTS
; -------
; zeroPoints: list
;     the locations where the zeros occur for observed and theoretical
;     modulating functions. the first row corresponds to the observed,
;     the second row corresponds to the theoretical
;-
  mfObs = MF_Observed(frFreq, R)
  mfTheory = MF_theory(frFreq, R, N)

END
FUNCTION MF_observed, frFreq, R
;+
; OVERVIEW
; --------
; will calculate the Observed Fringe Modulating Function as discussed in our 
; lab writeup
;
; CALLING SEQUENCE
; ----------------
; result = MF_observed(frFreq, R)
;
; PARAMETERS
; ----------
; frFreq: float
;     the local fringe frequency of the source in cycles/radian
; R: list
;     test radius values in meters
;
; OUTPUTS
; -------
; MF: list
;     the frindge modulator function
;-
  MF = sin(2.*!pi*frFreq*R) / (2.*!pi*frFreq*R) ; the computation
  return, [[2.*!pi*frFreq*R],[MF]]
END

FUNCTION MF_theory, frFreq, R, N
;+
; OVERVIEW
; --------
; will calculate the Theoretical Fringe Modulation Function as discussed in 
; our lab writeup
;
; CALLING SEQUENCE
; ----------------
; result = MF_theory(frFreq, R, N)
; 
; PARAMETERS
; ----------
; frFreq: float
;     the local fringe frequency of the source in cycles/radian
; R: list
;     test radius values in meters
; N: int
;     the number of data points in original data
;
; OUTPUTS
; -------
; MF: list
;     the frindge modulator function
;-
  littleN = findgen(2*N+1)-N           ; -N < n < +N
  MF = []
  FOR i = 0, n_elements(R)-1 DO BEGIN  ; loop through every R
    arg = 2.*!pi*frFreq*R[i]*littleN/N ; argument of cosine  
    MFCalc = (R[i]/N)*total( [1-(littleN/N)^2]^(1./2)*(cos(arg)) )
    MF = [MF, MFCalc]
  ENDFOR
  return, MF
END
