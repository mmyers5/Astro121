FUNCTION find_edges, filArr, doppFreq, sampFreq
;+
; OVERVIEW
; --------
; will take in spectra from filArr and plot each file spectrum. user can use
; trc, xx, yy to select the peak and the edge simultaneously. need to use right
; click
;
; CALLING SEQUENCE
; ----------------
; result=find_edges(filArr, doppFreq, sampFreq)
;
; PARAMETERS
; ----------
; filArr: list
;     the combined spectra from a set of files. each row is a file
; freqArr: list
;     the doppler corrections of the frequency axis of data in Hz
;     each row is a file
; sampFreq: float
;     the local oscillation frequency in Hz
;
; OUTPUTS
; -------
; edges: list
;     array containing information about the edges of each file. keep in mind
; which values you're interested in, i.e. whether you want the x or y-values, or
; both. to get x values, they're the 0th column, to get y get 1st column
;-
  n=8192
  nFile=(size(filArr))[2]          ; get the number of rows, i.e. how many files
  skyfreq = (findgen(n)*12.d6/n)+(150.d6)+1270.d6-6.d6      ; unshifted sky freq
  skyfreq /= (1.d6)                                         ; get freq in MHz
  doppFreq /= (1.d6)
  edges = []                                                ; empty array
  FOR i=0, nFile-1 DO BEGIN
    fixFreq = skyfreq-freqArr[i]                            ; shifted freq axis
    fixvel = (-(fixFreq-1420.4)*3.d8/1420.4)/(1.d3)         ; velo axis, km/s
    plot,fixvel, filArr[*,i],$                              ; plot stuff
      title='File Number'+string(i), ytitle='Temp (K)', xtitle='Velocity (km/s)',$
      /xstyle, xrange=[-100,500]
    trc, xx
    edges = [[edges],[xx],[yy]]
  ENDFOR
  return, edges 
END
