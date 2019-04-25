#!/usr/bin/python

#http://stackoverflow.com/questions/89228/how-to-call-external-command-in-python

#import subprocess
#return_code=subprocess.call(['identify', '/local/mnt/workspace/qgao/MyWork/Projects/Text_Recognition/CharImgsFromLOOKTeam/Flat/014663.bmp'])

#import os
#out=os.popen("ls -l").read()
#
#lines = out.split('\n')
#
#for ii in xrange( len(lines) ):
#    print '\"' + lines[ii] + '\"'

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

#from  FontStudyTool import *
#import sys
#
#if len(sys.argv) < 3:
#    print "Usage: test.py <char_seq> <font>"
#    sys.exit(-1)
#     
#print GetCharAspectRatio(sys.argv[1], sys.argv[2])    

#!/usr/bin/python
#
#

#from FontStudyTool import *
#import sys
#           
#if __name__ == '__main__':      
#    if len(sys.argv) < 2:
#        print "USAGE: test.py <font_name>"
#        print "   Narrow font on Linux: Helvetica-Narrow"
#        sys.exit(-1)
#    
#    fontName = sys.argv[1]
#    for asc in xrange(ord('A'), ord('Z') + 1):
#        prob = GetHppSkewDedectionProbForText ( chr(asc), fontName, 18, 1)        
#        print chr(asc), prob
#
#        
#    for asc in xrange(ord('a'), ord('z') + 1):
#        prob = GetHppSkewDedectionProbForText ( chr(asc), fontName, 18, 1)        
#        print chr(asc), prob        

from pylab import *
figure()
plot([1,2,3])
show()

