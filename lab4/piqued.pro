PRO get_delV_tA, gauss, delV, tA, cen
;+
; OVERVIEW
; --------
; will get relevent delV from array
;
; CALLING SEQUENCE
; ----------------
; get_delV_tA, gauss, delV, tA, cen
;
; PARAMETERS
; ----------
; gauss: struct
;     the structure from unpack_gauss
;
; OUTPUTS
; -------
; delV: list
;     the dispersion from the maximum velocity shifted things in km/s
; tA: list
;     the heights of the peaks of the shifted things
;-
  velos = gauss.wid
  tAs = gauss.hgt
  cens = gauss.cen
  nRow = (size(velos))[2]
  delV = make_array(nRow)
  tA = make_array(nRow)
  cen = make_array(nRow)
  FOR i = 0, nRow-1 DO BEGIN
    IF velos[2,i] NE 0. THEN BEGIN
      delV[i]=velos[2,i]
      tA[i]=tAs[2,i]
      cen[i]=cens[2,i]
    ENDIF ELSE IF velos[1,i] NE 0. THEN BEGIN
      delV[i]=velos[1,i]
      tA[i]=tAs[1,i]
      cen[i]=cens[1,i]
    ENDIF ELSE BEGIN
      delV[i]=velos[0,i] 
      tA[i]=tAs[0,i]
      cen[i]=cens[0,i]
    ENDELSE
  ENDFOR
  metric = 0.30938688           ; length of one tick in velo space in km/s
  delv*=metric
END 

FUNCTION unpack_gauss, fileTag, nFiles
;+
; OVERVIEW
; --------
; will unpack the hgt cen and wid info from savefiles
;
; CALLING SEQUENCE
; ----------------
; result = unpack_gauss(fileTag, nFiles)
;
; PARAMETERS
; ----------
; fileTag: list
;     the filetag names of the files you done saved
; nFiles: integer
;    the number of files that you want to look at
;
; OUTPUTS
; -------
; gauss: struct
;     the array that stores hgt, cen, and wid in columns. tags are hgt, cen, wid
;-
  hgt = make_array(3, nFiles)
  cen = make_array(3, nFiles)
  wid = make_array(3, nFiles)
  FOR i = 0, nFiles-1 DO BEGIN
    j = string(i, format='(I03)')                   ; string-ify
    filename = './'+fileTag+'_'+j+'_.sav'           ; get filename
    restore, filename                               ; restore it
    k=n_elements(hgt1)-1                             ; get element number
    hgt[0:k,i] = hgt1                               ; magic
    cen[0:k,i] = cen1
    wid[0:k,i] = wid1 
  ENDFOR
  gauss = {hgt:hgt, cen:cen, wid:wid}
  RETURN, gauss
END

PRO find_waldo, specArr, hgtArr, cenArr, widArr
;+
; OVERVIEW
; --------
; will let you fit up to three gaussians to data
;
; CALLING SEQUENCE
; ----------------
; find_waldo, specArr, gFitted
;
; PARAMETERS
; ----------
; specArr: list
;     the list of spectra, each row is a new file
;
; OUTPUTS
; -------
; hgtArr: list
;     array of heights, each column corresponds to a curve
; cenArr: list
;     same as hgtarr but for centers
; widArr: list
;     same as hftarr but for widths
;-
  nRow = (size(specArr))[2]                     ; number of rows
  FOR i=0, nRow-1 DO BEGIN
    plot, specArr[*,i], title=string(i), xrange=[3000,5000]
    read, 'How many curves do you want to fit? ', num
    PRINT, 'Get peaks (x and y)'
    trc, cen0, hgt0 & wait, 0.2                            ; store cen and hgt
    PRINT, 'Where is all this data? left and right (x) '
    trc, xx, /accumulate & wait, 0.2                       ; get domain
    xData = findgen( fix(abs(xx[1]-xx[0])) ) + xx[0]
    tData = specArr[[xData],i]                             ; get data in domain
    IF num EQ 1 THEN BEGIN
      PRINT, 'Get left and right edge, half-width (x)'
      trc, wid, /accumulate & wait, 0.2                    ; half width
      wid0 = abs(wid[1]-wid[0])
    ENDIF
    IF num EQ 2 THEN BEGIN
      PRINT, 'Get left and right edge, half-width (x)'
      trc, wid, /accumulate & wait, 0.2                    ; half width
      wid0 = [abs(wid[1]-wid[0]), abs(wid[3]-wid[2])]
    ENDIF
    IF num EQ 3 THEN BEGIN
      PRINT, 'Get left and right edge, half-width (x)'
      trc, wid, /accumulate & wait, 0.2                    ; half width
      wid0 = [abs(wid[1]-wid[0]), abs(wid[3]-wid[2]), abs(wid[5]-wid[4])]
    ENDIF
    gfit, -1, xData, tData, 0., hgt0, cen0, wid0,$         ; gaussian fit
      tfit, sigma, zro1, hgt1, cen1, wid1,$
      sigzro1, sighgt1, sigcen1, sigwid1, cov
    oplot, xData, tfit, color=!green                       ; for check
    read, 'Hit 1 if you want to keep going ', q            ; like it?
    IF q NE 1 THEN BEGIN
      i-=1
      CONTINUE
    ENDIF
  save, xData, tData, hgt1, cen1, wid1,$                  ; save stuff
    sigma, sigzro1, sighgt1, sigcen1, sigwid1, cov,$
    filename='gaussian2_'+string(i, format='(I03)')+'_.sav'
  ENDFOR
END
    
PRO find_fixvel, doppFreq, fixvelArr
  N = 8192.
  skyfreq = (findgen(n)*12.d6/n)+(150.d6)+1270.d6-6.d6      ; unshifted sky freq
  skyfreq /= (1.d6)                                         ; get freq in MHz
  doppFreq /= (1.d6)
  fixvelArr = []
  FOR i = 0, 125 DO BEGIN
    fixFreq = skyFreq-doppFreq[i]                           ; shifted freq axis
    fixvel = (-(fixFreq-1420.4)*3.d8/1420.4)/(1.d3)         ; velo axis, km/s
    fixvelArr = [[fixvelArr],[fixvel]]
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
  fatD = 400.                                ; 'size' of HI line
  dom = [3000,5000]                          ; area of interest
  FOR i=0, nRow-1 DO BEGIN
    plot, filArr[*,i], title=string(i), xrange=[3500,5000]
    trc, xx, /accum
    wait,0.1
    lowSide = findgen(100)+xx[0]-100
    highSide = findgen(100)+xx[1]
    cfx = [lowSide,highSide]                 ; complete set of x                        
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
    plot, filArr[*,i],title=string(i),xrange = [3500,5000] ; plot
    wait, waitTime                                 ; wait
  ENDFOR
END

FUNCTION find_edges, filArr, doppFreq, sampFreq, poi, xx=xx, yy=yy, xy=xy
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
  edges = make_array(poi,126)                               ; empty array
  FOR i=0, nFile-1 DO BEGIN
    fixFreq = skyfreq-doppFreq[i]                           ; shifted freq axis
    fixvel = (-(fixFreq-1420.4)*3.d8/1420.4)/(1.d3)         ; velo axis, km/s
    plot,fixvel, filArr[*,i],$                              ; plot stuff
      title='File Number'+string(i), ytitle='Temp (K)', xtitle='Velocity (km/s)',$
      /xstyle, xrange=[-200,600]
    trc, x, y                                       ; call trc
    wait, 0.1
    IF KEYWORD_SET(xx) THEN BEGIN
      edges[*,i]=x                                          ; store only x
    ENDIF 
    IF KEYWORD_SET(yy) THEN BEGIN
      edges[*,i]=y                                          ; store only y
    ENDIF 
    IF KEYWORD_SET(xy) THEN BEGIN
      edges[*,i]=[x,y]                                      ; store x and y
    ENDIF
  ENDFOR
  return, edges 
END
