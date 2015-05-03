PRO brita, filArr, x0, lazy=lazy
;+
; OVERVIEW
; --------
; will take an array (such as the one given by map_spec) and will perform a
; fourier filter in place. x0 is the same for all spec (i.e. be careful?)
;
; CALLING SEQUENCE
; ----------------
; brita, filArr, x0
; 
; PARAMETERS
; ----------
; filArr: list
;     spectra/spectrum that wants filtering
; x0: list
;     the start and stop places of the x-value where you want the fourier
;     transform to be zero'd, i like to use [100, 8000]
;
; KEYWORDS
; --------
; auto: set if you're lazy and want to use values that I THINK should work...
;-
  nRow = (size(filArr))[2]                  ; the number of rows
  IF KEYWORD_SET(lazy) then x0=[500,6000]   ; what my value of x0 is
  fftSpec = fft(filArr)                     ; take fourier transform
  fftSpec[x0[0]:x0[1],*] = 0.               ; zero out noise
  filArr = fft(fftSpec, /inverse)           ; inverse transform
END 

PRO dopp_spec, logFile, loFreq, velo, doppFreq
;+
; OVERVIEW
; --------
; will read the logfile specified by a particular fileTag and grab relevant data
; to doppler shift the spectra that presumably belong to the logfile
;
; CALLING SEQUENCE
; ----------------
; dopp_spec, logFile, loFreq, velo, doppFreq
;
; PARAMETERS
; ----------
; logFile: string
;     the full filename of the logFile that was generated by the observation in
;     track_head
;
; OUTPUTS
; -------
; velo: list
;     the array of the doppler velocities in km/s
; doppFreq: list
;     the doppler shifted frequencies in Hz
;-
  hFreq=1420.4d6 ; frequency of HI line in Hz
  N=8192 ; get number of elements per spectrum
  sampFreq=24d6 ; sampling frequency
  ;readcol, logFile, j, ra, dec, jDay,$ ; read logfile, j is number of file
  ;  format='IFFD'                      ; integer, float, float, double
                                       ; (ra,dec) in degrees in 2000 equinox
                                       ; jDay is normal
  ra=logFile[*,0]
  dec = logFile[*,1]
  jDay = logFile[*,2]
  c=3.e8
  ra*=(24./360) ; convert ra to decimal hours
  velo=(ugdoppler(ra, dec, jDay, nlat =37.8732, wlong=122.2573))[3,*] ; DOPP-IT!
                                                                 ; units km/s
  doppFreq=-(hFreq)*(velo*10^3)/(c)
END

FUNCTION map_spec, fileTag, startFile, endFile, nSpectra
;+
; OVERVIEW
; --------
; function will read all the files generated by leuschner_rx that has a fileTag.
; assumes the files are incremented regularly. then smooths and calibrates the
; spectra in each file and stores the smoothed spectra in an array
;
; CALLING SEQUENCE
; ----------------
; result = map_spec(fileTag, nFiles, nSpectra)
;
; PARAMETERS
; ----------
; fileTag: string
;     assumes that the data files are in ./data, is the fits file for spec
;     incremented up to three digits of precision, i.e. 'fileTag_001', where
;     line status is contained in fileTag
; nFiles: integer
;     the number of files you got
; nSpectra
;     the number of spectra in each fits file, or extension number
;
; OUTPUTS
; -------
; filArr: list
;     array containing smoothed and calibrated spectra of each file
;     each row is a file
;-
  N = 8192                      ; number of spectra per file
  nFile = endFile-startFile     ; number of actual files
  filArr = make_array(N, nFile+1) ; holds spectra for each file
                                ; each row is a file
  p = 0                         ; force index
  FOR i=startFile, endFile DO BEGIN
    j = STRING(i, FORMAT='(I03)') ; get increment value
    fileTagx = './data/'+fileTag+'_'+j ; for passing into channel_sort
    filArr[*,p] = channel_sort(fileTagx, nSpectra) ; get spectrum in file
    p+=1                          ; end index
  ENDFOR
  RETURN, filArr
END

FUNCTION channel_sort, fileTagx, nSpectra
;+
; OVERVIEW
; --------
; function will read files as generated by leuschner_rx,
; then will combine all the spectra from each file into one spectrum after
; calibraton
;
; CALLING SEQUENCE
; ----------------
; result = channel_sort(fileTagx, nSpectra)
;
; PARAMETERS
; ----------
; fileTagx: string
;     assumes that the data files are in ./data, is the fits file for spec
;     typical name: 'fileTagx_on.fits', x = '_increment number'
; nSpectra: int
;     give the number of spectra used when you used leuschner_rx. same as
;     extension number for using mrdfits
;
; OUTPUTS
; -------
; specArr: list
;     an array containing the smoothed and calibrated spectra
;-
  N = 8192 ; the number of elements from each extension
  extArr0 = make_array(N, nSpectra) ; holds spectra from extensions of one file
                                    ; each row is an extension
  extArr1 = make_array(N, nSpectra)
  onFil = fileTagx+'_on.fits' ; for on spectra
  FOR k=1, nSpectra DO BEGIN ; loop through extensions
    print, onFil
    onSpec = mrdfits(onFil,k)    ; unpack ext on
    extArr0[*,k-1] = calib(onSpec.auto0_real, 0) ; since we didn't take offlines
    extArr1[*,k-1] = calib(onSpec.auto1_real, 0)
  ENDFOR
  specArr = median([[extArr0],[extArr1]], DIMENSION = 2) ; smooth the things
  RETURN, specArr
END

FUNCTION calib, onSpec, offSpec
;+
; OVERVIEW
; --------
; will calibrate spectra
;
; CALLING SEQUENCE
; ----------------
; result = calib(onSpec, offSpec)
;
; PARAMETERS
; ----------
; onSpec: list
;     the online spectrum
; offSpec: list
;     the offline spectrum
;
; OUTPUTS
; -------
; calSpec: list
;     the final calibrated spectrum
;-
  coldSpec = (mrdfits('./data/coldSpec.fits', 1)).auto0_real ; spec of cold
  hotSPec = (mrdfits('./data/hotSpec.fits', 1)).auto0_real   ; spec of hot
  ;ratio = onSpec/offSpec ; get shape of line
  ratio = onSpec
  Tsys = (total(coldSpec)/total(hotSpec-coldSpec)) * 20 ; sys temperature
  calSpec = ratio*Tsys ; final calibrated spectrum
  RETURN, calSpec
END
