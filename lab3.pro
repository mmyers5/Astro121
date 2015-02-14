PRO file_orgy, nSamp, voltThreshold, picoArgs, fileTag, correction = nFile
;+
; OVERVIEW
; --------
; Procedure will invoke picosampler however many times specified
; and will label them based on user input. make sure you're in the
; directory you want it to be saved in
;
; CALLING SEQUENCE
; ----------------
; file_orgy, nSamp, voltThreshold, picoArgs, fileTag, correction = nFile
;
; PARAMETERS
; ----------
; nSamp: int
;     the number of times you want picosampler to be sampled
; picoArgs: array
;     must be an array specifying the arguments to be passed into 
;     picosampler. will automatically string-ify the voltage info.
;     recall sequence is VoltThreshold, sampInterval, nSpectra, /dual.
;     to set /dual, type 1, else type 0.
; fileTag: string
;     how you want to label the files. files are named starting with the 
;     file tag, its place in line, the sampling frequency, the date,
;     then the time. E.G. if you labeled the filetag as 'test_tag' and 
;     first sampled on february 11 at 8:59 pm at 62.5MHz, the filename 
;     would be "test_tag_0211_2059_62.5MHz_0.bin"
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

sampInterval = picoArgs[1]
nSpectra = picoArgs[2]
duality = picoArgs[3]

leFreq = 62.5/sampInterval                        ; get sampling frequency

IF N_ELEMENTS(nFile) EQ 0 THEN start=0 ELSE start=nFile   ; check if a correction needs to be made

FOR i=start, start+nSamp-1 DO BEGIN                     ; recall both start and end indices are inclusive
   filename = picosampler(voltThreshold, sampInterval, nSpectra, dual = duality)   ; call picosampler
   
   timeTag = systime(/JULIAN)                     ; get julian time
   caldat, timeTag, mo, day, yr, hr, min, sec     ; unpack time
   
   fileButt = string(mo)+string(day)+'_'$         ; get time-marked filename
              +string(hr)+string(min)+'_'+string(leFreq, format ='(3f0.1)')+'MHz_'$
              +string(i)+'.bin'
   destination= strjoin(STRSPLIT(fileTag+'_'+fileButt, /EXTRACT))
   file_copy, filename, './data/'+destination      ; copy and rename file

ENDFOR

END
