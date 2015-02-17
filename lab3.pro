PRO file_orgy, nSamp, voltThreshold, picoArgs, fileTag, correction = nFile
;+
; OVERVIEW
; --------
; Procedure will invoke picosampler however many times specified
; and will label them based on user input. make sure you have a
; directory called "data" in your present working directory. will output
; to a logfile named after the filetag that will contain info about the
; parameters sent to picosampler, subsequently adding the date and time
; when the samples were finished.
; format will be date (month/day), time (24hr), and sample
; number. E.G. the first sample finished on february at 8:59 will be
; laveled as "0211_2059_00" in the log
;
; CALLING SEQUENCE
; ----------------
; file_orgy, nSamp, voltThreshold, picoArgs, fileTag, correction = nFile
;
; PARAMETERS
; ----------
; nSamp: int
;     the number of times you want picosampler to be sampled, or the
;     number of files you want to have by the end
; voltThreshold: string
;     the parameters for picosampler, written as '1V', or '100mV' etc...
; picoArgs: array
;     must be an array specifying the arguments to be passed into 
;     picosampler. recall sequence is VoltThreshold, sampInterval,
;     nSpectra, /dual.  to set /dual, type 1, else type 0. VoltThreshold
;     should be input as an integer
; fileTag: string
;     how you want to label the files. files are named starting with the 
;     file tag, followed by the sample number. E.G. the first file
;     created by picosampler with fileTag 'test' will be 'test_00.bin'
;
; KEYWORDS
; --------
; correction: int
;     if for some reason you stopped taking data and wanted to resume
;     where it left off, then you can invoke this argument to start 
;     doing simulations starting at this numberfile. the number of 
;     times to sample will be reduced by whatever amount is specified
;     in nFile
;- 

sampInterval = picoArgs[1]                        ; unpack the picoArgs list to be put into picosampler
nSpectra = picoArgs[2]
duality = picoArgs[3]

leFreq = 62.5/sampInterval                        ; get sampling frequency
leFreq = string(leFreq, format='(f0.1)')          ; make sure frequencies go up to one decimal digit
IF N_ELEMENTS(nFile) EQ 0 THEN start=0 ELSE start=nFile   ; check if a correction needs to be made

openw, 1, fileTag+'.log', /APPEND                 ; append to log file based on filetag
printf, 1, format='("VoltThreshold", 4X, "sampInterval", 4X, "nSpectra", 4X, "dual")'
printf,1,  format='(A13,I16,I12,I8)', voltThreshold, sampInterval, nSpectra, duality
close, 1

FOR i=start, start+nSamp-1 DO BEGIN                     ; recall both start and end indices are inclusive
   filename = picosampler(voltThreshold, sampInterval, nSpectra, dual = duality) ; call picosampler
   
   timeTag = systime(/JULIAN)                     ; get julian time
   caldat, timeTag, mo, day, yr, hr, min, sec     ; unpack time
   
   openw, 1, fileTag+'.log', /APPEND              ; add info about time to logfile
   printf, 1, format='(I02, I02, "_", I02, I02, "_", I02)',$
           mo, day, hr, min, i
   close, 1

   destination = STRJOIN(STRSPLIT(fileTag+'_'+$
                                  string(i, format='(I02)')+$
                                  '.bin', /EXTRACT)) ; put filename together and extract whitespaces
   file_link, filename, './data/'+destination        ; create a symbolic link to file using destination name

ENDFOR

END

PRO channel_sort, fileTag, binArr
;+
; OVERVIEW
; --------
; Procedure will re-organize picosampler binary file data if they were taken
; with nSpectra > 1. Will read the binary files and output legibly to
; specArr, or at least it works like that on my computer. heavily
; simplified to work at lab
;
; CALLING SEQUENCE
; ----------------
; channel_sort, fileTag, nFiles, nSpectra, specArr
;
; PARAMETERS
; ----------
; fileTag: string
;     must be the fileTag used in file_orgy procedure to help user
;     select the binary files that need the channels sorted
; nFiles: int
;     the number of binary files labeled with fileTag. Must be
;     incremental
; nSpectra: int
;     give the number of spectra used when you used picosampler. Should
;     have been output to a .log file if used file_orgy to call
;     picosampler
;
; OUTPUTS
; -------
; specArr: array
;     an array of shape (nChannel, nSpectra). will re-organize things so
;     that the spectra from channel 1 is in the first row, and
;     spectra from channel 2 is in the second row (as IDL sees
;     it). Each row should contain continuous spectra shared by both
;     channels.
;-

;N=long(16000)                                      ; elements for one spectrum for one channel
;numCols = ulong(N*nSpectra*nFiles)            ; get size of how many sample points there are per channel
;numEls = ulong(nSpectra*N)                    ; elements for one channel
   
filename = './data/'+fileTag+'.bin'              ; put filename together
   
binArr = read_binary(filename, data_type=2)      ; read binary file 
END

PRO power_spec, realArr, imagArr, specPF

;+
; OVERVIEW
; --------
; procedure will take power spectra of input arrays and shift them to be
; centered accordingly
;
; CALLING SEQUENCE
; ----------------
; power_spec, realArr, imagArr, specPF
;
; PARAMETERS
; ----------
; realArr: array
;     input array from channel 1
; imagArrArr: array
;     input array from channel 2
; 
; OUTPUTS
; -------
; specPF: array
;     the power spectrum of the input array
;-

compArr = complex(realArr, imagArr)            ; make one giant mega-complex array

specFT = fft(compArr)                          ; take fourier transform of complex array
N = size(specFT, /N_ELEMENTS)
specFT = shift(specFT, N/2)                    ; shift ft to be centered on zero

specPF = (abs(specFT))^2                       ; take power spectrum

END

PRO smooth_operator, onArray, offArray, coldArray, hotArray, numChan, finalArray
;+
; OVERVIEW
; --------
; will take the median of arrays for smoothing stuff and put them
; together to get the final final final array we're looking for
;
; CALLING SEQUENCE
; smooth_operator, onArray, offArray, coldArray, hotArray, numChan, finalArray
;
; PARAMTERS
; ---------
; onArray: array
;     should be power spectrum from online data
; offArray: array
;     should be power spectrum from offline data
; coldArray: array
;     power spectrum of data of the cold unforgiving sky
; hotArray: array
;     power spectrum of data from our portable sacks of water
; numChan: int
;     number of channels over which you would like the median to be
;     measured
;
; OUTPUTS
; -------
; finalArray: array
;     the output array after it has been smoothed
;-

onArray = median(onArray, numChan)            ; median over online data
offArray = median(offArray, numChan)           ; median over offline data

;scoldArray = median(coldArray, numChan)             ; median over cold data
;shotArray = median(hotArray, numChan)               ; median over hot data

finalArray = onArray/offArray  ;; TEMPORARY
;ratio = onArray/offArray
;Tsys = (total(scoldArray)/total(shotArray - scoldArray) )*(300) ; get Tsys, look at pg 6 of lab thing

;finalArray = ratio*Tsys

END

PRO cheating_doppler, JT, delF
;+
; OVERVIEW
; --------
; will calculate the doppler shifted frequency change using a cheaty
; method
;
; CALLING SEQUENCE
; ----------------
; cheating_doppler, JT, delF
;
; PARAMETERS
; ----------
; JT: float
;     the julian time at which you want this calculated
;
; OUTPUTS
; -------
; delF: float
;     the change in frequency due to the doppler shifting!

lati = 37.8717                                    ; latitude of Berkeley
longi = 122.2728                                  ; longitude of Berkeley
tz = 8                                            ; time zone of Berkeley

zenpos, JT, ra, dec             ; call cheating procedure
                                ; it will ask you to input lati, longi,
                                ; and tz

ra = ra*(180./!pi)*(24/360.)                      ; convert to decimal hours
dec = dec*(180./!pi)                              ; convert to decimal degrees

vel = ugdoppler(ra, dec, JT)                      ; call doppler shift procedure
c = 3.e8

delF = -1*(v/c)*(1420.4058)                       ; gives delta f in MHz

END  
