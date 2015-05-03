PRO unpack_head, fileTag, jArr
  jArr = []
  FOR i = 0, 39 DO BEGIN
    j = string(i, format='(I03)')
    a = mrdfits('./data/'+fileTag+'_'+j+'_on.fits', 1, h)
    jDay = (strsplit(h[16], ' ', /extract))[2]
    jArr = [[jArr],[jDay]]
  ENDFOR
END
