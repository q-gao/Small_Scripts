#!/usr/bin/python


from  FontStudyTool import *
import sys

if len(sys.argv) < 3:
    print "Usage: test.py <char_seq> <font_name> [rotate_angle]"
    sys.exit(-1)

if len(sys.argv) >= 4:
    rotate = sys.argv[3]
else:
    rotate = '0'
    
print GetCharPortionPercentage(sys.argv[1], sys.argv[2], rotate)
#
#
#imgFile = 'ab.gif'
#
##cc= DetectLeftCCFromImage(imgFile)
##GrayScaleNumpyMatrix(cc)
##cc = DetectRightCCFromImage(imgFile)
##GrayScaleNumpyMatrix(cc)
#
#ccLeft, ccRight = DetectLeftRightCCFromImage(imgFile)
#BwScaleNumpyMatrix(ccLeft)
#BwScaleNumpyMatrix(ccRight)

#from CalcMinCCDistance import *
#
#print CalcMinCCGapInImage('ab.gif')
#    
