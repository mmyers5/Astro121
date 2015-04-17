pro do_dft_spec, myFile, start, finish, pfOut, f
;+
; OVERVIEW
; --------
; will perform discrete fourier transform of data to get power spectra
; 
; CALLING SEQUENCE
; ----------------
; do_dft_spec, myFile, start, finish, pfOut, f
;
; PARAMETERS
; ----------
; myFile: string
;     path to the savefile where voltage information is stored
; start: int
;     the starting index where you want data analyzed
; finish: int
;     the ending index where you want data analyzed
;
; OUTPUTS
; -------
; dftOut: list
;     the output of the power spectrum run through dft
; f: list
;     the frequency axis of power spectrum in Hz
;-
    restore, myFile                     ; restore savefile
    inArr = (str.volts)[start:finish]
    N = n_elements(inArr)               ; get number of elements
    t = (str.julday)[start:finish]      ; get relevant times
    t = (t - t[0]) * 86400d             ; calculate time relative to initial
    tInterv = (t[-1]-t[0])/float(N)     ; get time interval
    vSamp = 1./tInterv
    f = (findgen(N)-(N/2.))*(vSamp/float(N)) ; get frequence axis
    dft, t, inArr, f, dftOut            ; perform dft, yay
    pfOut = (abs(dftOut))^2             ; get power spectrum
END

pro loc_fringe_freq, haDecFile, start, finish, locFreq, baseLine, outFreq
;+
; OVERVIEW
; --------
; will compute the local fringe frequency
;
; CALLING SEQUENCE
; ----------------
; loc_fringe_freq, haDecFile,start, finish, locFreq, baseLine, outFreq
;
; PARAMETERS
; ----------
; haDecFile: list
;     the savefile that stores the hour angle info under variable ha
;     and dec under variable dec
; locFreq: float
;     the local oscillation frequency set by the interferometers
; baseLine: float
;     the baseline distance between the two telescopes in meters
; 
; OUTPUTS
; -------
; outFreq: list
;     the output array of local fringe frequencies we should expect to see in our data
;-
    restore, haDecFile
    ha = ha[start:finish]
    dec = dec[start:finish]
    lambda = 3d8/locFreq  ; get wavelength
    outFreq = (baseLine/lambda)*cos(dec)*cos(ha) ; do computation, output in cycles/rad
    outFreq *= (2.*!pi)/(24.*60*60)              ; convert to cycles/sec
END
