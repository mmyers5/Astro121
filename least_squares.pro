PRO fit_it, y0, x0, yBar, delY, sTd, diagXXI, varDC
  
  numY = n_elements(y0)              ; get the number of elements in the measured values
  x0Partial = findgen(numY)          ; set the null number for the x matrix
  x0 = make_it(x0Partial)            ; get the full x-matrix, with the zeroth order term set to 1
 
  N = (size(x0))[2]                  ; get nuber of rows, i.e. unknowns
  M = (size(x0))[1]                  ; get number of columns, i.e. data points

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

FUNCTION make_it, n0
  
  numN = n_elements(n0)
  n0Arr = make_array(2, numN, VALUE=1.)
  FOR i= 0, numN - 1 DO BEGIN
     n0Arr[1,i] = n0[i]
  ENDFOR
  
  RETURN, n0Arr

END
