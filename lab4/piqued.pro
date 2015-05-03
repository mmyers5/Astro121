PRO find_waldo, filArr,gaussArr
;
; OVERVIEW
; --------
; will let you do gaussian fitting for every curve in filArr. will prompt for
; guesses, DOESN'T WORK!!
;
; CALLING SEQUENCE
; ----------------
; find_waldo, filArr, HIdomain, gaussArr
;
; PARAMETERS
; ----------
; filArr: list
;     the spectra to look at, presumably already lined
;
; OUTPUTS
; -------
; gaussArr: list
;     the gaussian fits for the spectra, each row is a spectrum
;-
  HIdomain = [3000,5000]                            ; where HI line kind of is
  nRow = (size(filArr))[2]                          ; row count
  gaussArr = []
  FOR i=20, nRow-1 DO BEGIN
    plot, filArr[*,i], title=string(i), xrange=HIdomain
    nl = string(10B)
    PRINT, 'Click 1: Start of all HI Line (x)'+nl,$
           'Click 2: End of all HI Line (x)'+nl,$
           'Click 3: Peak of first HI Line (x&y)'+nl,$
           'Click 4: Peak of second HI Line (x&y)'+nl,$
           'Click 5: Halfwidth Start of First HI Line (x)'+nl,$
           'Click 6: Halfwidth End of First HI Line (x)'+nl,$
           'Click 7: Halfwidth Start of Second HI Line (x)'+nl,$
           'Click 8: Halfwidth End of Second HI Line (x)'
    trc, xx, yy, /accum                             ; ask for guesses
    xData = dindgen(fix(xx[1]-xx[0]))+fix(xx[1])  ; get x-domain
    tData = filArr[xData,i]                         ; get y-values
    hgt0 = [yy[2],yy[3]]                            ; get peaks
    cen0 = [xx[2],xx[3]]                            ; get centers
    wid0 = [xx[5]-xx[4],xx[7]-xx[6]]                ; get widths
    gfit, -1, xData, tData, 0.08, hgt0, cen0, wid0,$
      tfit, sigma, zro1, hgt1, cen1, wid1
    oplot, tfit
    STOP
    gaussArr = [[gaussArr],[tfit]]
    STOP
  ENDFOR
END

PRO find_line, filArr
;+
; OVERVIEW
; --------
; will let you find the equation of "the line" and corrects spectra in place
;
; CALLING SEQUENCE
; ----------------
; find_line, filArr
;
; PARAMETERS
; ----------
; filArr: list
;     the combined spectra from a set of files. each row is a file
;
; OUTPUTS
; -------
; filArr: list
;     the spectra originally passed in but corrected with proper line
;-
  nRow = (size(filArr))[2]                   ; row count
  fatD = 500.                                ; 'size' of HI line
  dom = [3000,5000]                          ; area of interest
  FOR i=0, nRow-1 DO BEGIN
    peakY = max(filArr[dom[0]:dom[1],i])                  ; find peak of line
    peakX = (where(filArr[dom[0]:dom[1],i] EQ peakY))[0]  ; find peak x vlaue
    cfx0=(findgen(100))+peakX-(fatD/2.)-100.              ; make arrays
    cfx1=(findgen(100))+peakX+(fatD/2.)
    cfx = [cfx0,cfx1]                                     ; complete set of x                        
    cfy = filArr[cfx,i]                                   ; complete set of y
    polyfit, cfx, cfy, 1, lineArr                         ; perform fit
    line = lineArr[0] + (findgen(8192)*lineArr[1])        ; eqn of line per row
    filArr[*,i] = filArr[*,i]-line                        ; subtract line
  ENDFOR
END  

PRO see_plot, filArr, waitTime, xx
;+
; OVERVIEW
; --------
; will let you see what rough plots look like
;
; CALLING SEQUENCE
; ----------------
; see_plot, filArr, waitTime, xx
;
; PARAMETERS
; ----------
; filArr: list
;     some sort of list of spectra you want to look at 
; waitTime: float
;     time between each plot
;-
  nRow = (size(filArr))[2]                         ; number of rows
  FOR i=0, nRow-1 DO BEGIN 
    plot, filArr[*,i],title=string(i), yrange=[-0.05,0.15],xrange = [3000,5000] ; plot
    wait, waitTime                                 ; wait
  ENDFOR
END

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
; which values you're interested in, i.e. whether you want x, y, or both 
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
    fixFreq = skyfreq-doppFreq[i]                            ; shifted freq axis
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
