#!/usr/bin/python

from pylab import *
from FontStudyTool import *
import os
import sys
               
if __name__ == '__main__':    
    if len(sys.argv) < 3:
        print "USAGE: VisualizeVericalProjectionProfile.py <text> <clock_wise_rotation> [<font_name>]"
        print "  Default font: Helvetica-Narrow"
        sys.exit(-1)
    
    rotate = sys.argv[2]
    
    if len(sys.argv) >= 4:
        fontName = sys.argv[3]
    else:
        fontName = 'Helvetica-Narrow'
        
    TMP_IMG_FILE = 'VisualizeVericalProjectionProfile_tmp_text.gif'    
    TMP_HPP_FILE = 'VisualizeVericalProjectionProfile_tmp_vpp.png'
    # Narrow font is more challenging
    cmd = 'convert -background black -fill white -pointsize 64 -font ' + fontName + ' -rotate ' + rotate + ' label:' + sys.argv[1] + ' ' + TMP_IMG_FILE
    print cmd
    os.system(cmd)
    
    vpp = GetVerticalProjectProfile(TMP_IMG_FILE)
    
    # Simple but faster plotting
    #-----------------------------------------------------------------
    #figure(figsize=(10, 3), dpi=80) # facecolor='w', edgecolor='k' #figure()
    #plot(vpp)
    #savefig(TMP_HPP_FILE)
    #
    #cmd = 'convert ' + TMP_HPP_FILE  + ' ' + TMP_IMG_FILE  + ' -append gif:- | display gif:-'
    ##print cmd
    #os.system(cmd)
    
    # Slow but nicer plotting
    #--------------------------------------------------
    BwScaleDotMatrixImage_NoShow(TMP_IMG_FILE)
    plot(vpp)
    show()
    
    cmd = 'rm ' + TMP_IMG_FILE + ' ' + TMP_HPP_FILE
    #print cmd
    os.system(cmd)
    

