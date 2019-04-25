#!/usr/bin/python

from pylab import *
from FontStudyTool import *
import os
import sys
        
    
if len(sys.argv) < 3:
    print "USAGE: VisualizeSkewDetection.py <text> <font_name> [<clock_wise_rotation>]"
    sys.exit(-1)

if len(sys.argv) >= 4:
    rotate = sys.argv[3]
else:
    rotate = '0'
    
TMP_IMG_FILE = 'StudySkewDetection_tmp_text.gif'    
TMP_HPP_FILE = 'StudySkewDetection_tmp_hpp.png'
# Narrow font is more challenging
cmd = 'convert -background black -fill white -pointsize 100 -font '+ sys.argv[2] +' -rotate ' + rotate + ' label:' + sys.argv[1] + ' ' + TMP_IMG_FILE
print cmd
os.system(cmd)

hpp = GetHorizontalProjectProfile(TMP_IMG_FILE)
print 'HPP width: ',  WidthWithoutLeftRightMargin(hpp)

figure(figsize=(3, 3), dpi=80) # facecolor='w', edgecolor='k' #figure()
plot(hpp)
savefig(TMP_HPP_FILE)

cmd = 'convert ' + TMP_IMG_FILE + ' -rotate -90 ' + 'gif:- ' + '| convert ' + TMP_HPP_FILE + ' - -append gif:- | display gif:-'
#print cmd
os.system(cmd)

cmd = 'rm ' + TMP_IMG_FILE + ' ' + TMP_HPP_FILE
#print cmd
os.system(cmd)
    

