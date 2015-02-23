PRO fitIt, filePath

  readcol, filePath + '.dat', x0, y0, format = 'F,F'  ; reads columns of data
  
  ; x0 = x-values, y0 = y-values
  ; shape (data points, 1)

  N = size(x0)[2]                    ; get nuber of rows, i.e. unknowns
  M = size(x0)[1]                    ; get number of columns, i.e. data points

  y0 = transpose(y0)                 ; turn y vector into a column vector for matrix ops
  XX = transpose(x0) ## x0           ; get alpha from the handout, xT * x
  XY = transpose(x0) ## y0           ; get beta from the handout, xT * y
  XXI = invert(XX)                   ; invert xT from the handout, xT^(-1)
  A = XXI ## XY                      ; least squares fit coefficients that we want

  yBar = x0 ## A                     ; predicted values, the function!

  delY = y0 - yBar                   ; uncertainties
  
  sTd = total(delY^2)/(M-N)          ; square of standard deviation

  diagXXI = XXI[(N+1) * indgen(N)]   ; get error in yBar

  varDC = sTd * diagXXI              ; variances of derived coefficients

END
