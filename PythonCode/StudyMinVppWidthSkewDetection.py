#!/usr/bin/python

#from pylab import *
from FontStudyTool import *
import os
import sys
        
    
if len(sys.argv) < 5:
    print "USAGE: StudyMinVppWidthSkewDetection.py <text> <rotation_start> <rotation_end> <rotation_step> [font_name]"
    print "   rotation specified in clock-wise angle in integers "
    sys.exit(-1)

rotate = sys.argv[2]
if len(sys.argv) >= 6:
    fontName = sys.argv[5]
else:
    fontName = 'Helvetica-Narrow' # narrow font is worse

TMP_IMG_FILE = 'StudySkewDetection_tmp_text.gif'    

rotateStep = int(sys.argv[4])
print 'Rotation ANgle, VPP width'
# Narrow font is more challenging
cmdHead = 'convert -background black -fill white -pointsize 64 -font ' + fontName + ' -rotate '
for rotate in xrange(int(sys.argv[2]), int(sys.argv[3])+rotateStep, rotateStep):   
    
    cmd =  cmdHead + str(rotate) + ' label:' + sys.argv[1] + ' ' + TMP_IMG_FILE
    #print cmd
    os.system(cmd)

    vpp = GetVerticalProjectProfile(TMP_IMG_FILE)
    print rotate,  WidthWithoutLeftRightMargin(vpp)

cmd = 'rm ' + TMP_IMG_FILE
#print cmd
os.system(cmd)
    

