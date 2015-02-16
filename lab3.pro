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

PRO channel_sort, fileTag, nFiles, nSpectra, specArr
;+
; OVERVIEW
; --------
; Procedure will re-organize picosampler binary file data if they were taken
; with nSpectra > 1. Will read the binary files and output legibly to
; specArr
;
; CALLING SEQUENCE
; ----------------
; channel_sort, fileTag, nSpectra, specArr
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
;     that the spectra from channel 1 is in the first column, and
;     spectra from channel 2 is in the second column (as IDL sees
;     it). Each row should contain continuous spectra shared by both
;     channels.
;-

N=long(16000)                                      ; elements for one spectrum for one channel
numCols = long(N*nSpectra*nFiles)            ; get size of how many sample points there are per channel
numEls = long(nSpectra*N)                    ; elements for one channel

specArr = make_array(numCols, 2, /INTEGER)

FOR i = 0, nFiles DO BEGIN                   ; loop through every file
   startInd = i*(numEls)                     ; get starting index of binary array
   endInd = startInd + (numEls-1)       ; get ending index of binary array

   j = string(i, format='(I02)')             ; get file number to be two digits
   filename = './'+fileTag+'_'+j+'.bin' ; put filename together
   
   binArr = read_binary(filename, data_type=2,$
                         data_dims=[numEls,2])      ; read binary file
                                ; data_dims puts the first channel 
                                ; elements in column 1, the next channel
                                ; elements in column 2
   specArr[startInd:endInd,*] = binArr     ; do the copy proper

ENDFOR
 
END

PRO power_spec, binArr, sampInterval, specPF

vSamp = 62.5/sampInterval

N = size(binArr, /N_ELEMENTS)
NN = N/2

realArr = binArr[0:(NN)-1]
imagArr = binArr[NN:-1]
compArr = complex(realArr, imagArr)

specFT = fft(compArr)
specPF = (abs(specFT))^2

f = (findgen(NN)-(NN/2))*(vSamp)

plot, f, shift(specFT, NN), /xstyle

END

PRO rotten_matrix, LST

leMatrix = make_array(3,3)

leMatrix[0,0] = cos(LST)
leMatrix[0,1] = -1*sin(LST)
leMatrix[0,2] = 0.
leMatrix[1,0] = sin(LST)
leMatrix[1,1] = cos(LST)
leMatrix[1,2] = 0.
leMatrix[2,0] = 0.
leMatrix[2,1] = 0.
leMatrix[2,2] = 1.

END
