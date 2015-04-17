pro plotsmilk, x_array, y_array, plot_title, x_title, y_title, file_name, x_size, y_size, xs=xsty, ys=ysty

;+
; OVERVIEW
; --------
; This procedure plots the specified data and saves it as
; file_name.ps in the plots directory in Astro121. 
; Use this often to save plots along the way your lab
; report.
; 
; CALLING SEQUENCE
; ----------------
; plotsmilk, x_array, y_array, plot_title, x_title, y_title, file_name,
; x_size, y_size
;
;PARAMETERS
;----------
;x_array: array
;   the array of your independent axis, like frequency or time
;y_array: array
;   the data to be plotted against the x array, like the power spectrum
;plot_title: string
;   the title of the plot to be displayed on the final image
;x_title: string
;   the name of the x axis, such as 'frequency (Hz)'. Include units
;y_title: string 
;   the name of the y axis, such as 'voltage (V)'. Include units
;file_name: string
;   the name you want the plot to be saved as, without including the
;   .ps, such as 'power_spectrum_01'. This procedure will add the '.ps'
;   to the filename and name the file 'power_spectrum_01.ps'
;x_size: integer
;   the size, in inches, of the horizontal dimension of the final plot 
;y_size: integer
;   the size, in inches, of the vertical dimension of the final plot
;-


  file_name_ps = strjoin([file_name,'ps'],'.')
  file_name_full = strjoin(['~/Astro121/plots',file_name_ps],'/')

  ps_ch, file_name_full, xsize=x_size, ysize=y_size, /inches

  plot, x_array, y_array, title=plot_title, xtitle=x_title, ytitle=y_title, xstyle=xsty, ystyle=ysty

  ps_ch, /close

end  
  
