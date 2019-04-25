#!/usr/bin/python
#
#

from FontStudyTool import *
import sys

if __name__ == '__main__':      
    if len(sys.argv) < 2:
        print "USAGE: StudyRotatedCharHeightWithHpp <font_name>"
        print "   Narrow font on Linux: Helvetica-Narrow"
        sys.exit(-1)
        
    maxRotAngle = 9 # in degree. Should be an integer
    char = GenEnglishNumAlphabet()

    line =  ' '
    for ii in xrange(-maxRotAngle, maxRotAngle + 1):
        line += (',' + str(ii))
    print line
    sys.stdout.flush()
    
#        charHeight = []        
    for ii in xrange( len(char) ):
        c = char[ii];
        h = EstTextHeightViaHppAverage(c, sys.argv[1], maxRotAngle, maxRotAngle)            
#            charHeight.append(
#                              EstTextHeightViaHppAverage(c, sys.argv[1], maxRotAngle, maxRotAngle)
#                              )
        line = c
        for a in xrange( len(h) ):
            line += ',' + str( h[a] )
        print line
        sys.stdout.flush()
    
        
        
          