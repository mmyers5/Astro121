FUNCTION find_edges, filArr, doppFreq, sampFreq, xx=xx, yy=yy, xy=xy
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
; KEYWORDS
; --------
; xx:
;     if you only want the x-values, specify this keyword
; yy:
;     if you only want the y-values, specify this keyword
; xy:
;     if you want both the x-and-y values, specify this keyword
;
; OUTPUTS
; -------
; edges: list
;     array containing information about the edges of each file. keep in mind
; which values you're interested in, i.e. whether you want the x or y-values, or
; both 
; if you specify xx, every row of edges will be for individual plots. same
; for yy. if you specify xy, every row of edges will be for an individual plot,
; with the first half of the columns being for x and second half being for y
; if you want to select more than one trc, you have to do left-click then
; right-click, and do this consistently
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
    trc, xx, yy                                             ; call trc
    IF KEYWORD_SET(xx) THEN BEGIN
      edges = [[edges],[xx]]                                ; store only x
    ENDIF ELSE IF KEYWORD_SET(yy) THEN BEGIN
      edges = [[edges],[yy]]                                ; store only y
    ENDIF ELSE IF KEYWORD_SET(xy) THEN BEGIN
      edges = [[edges],[xx],[yy]]                           ; store x and y
    ENDIF
  ENDFOR
  return, edges 
END
