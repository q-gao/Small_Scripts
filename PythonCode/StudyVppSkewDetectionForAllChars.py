#!/usr/bin/python
#
#
from FontStudyTool import *
import os
import sys
           

if __name__ == '__main__':      
    if len(sys.argv) < 4:
        print "USAGE: StudyVppSkewDetectionForAllChars.py <rotation_max> <rotation_step> <font_name>"
        print "   rotation specified in clock-wise angle in integers "
        print "   Narrow font on Linux: Helvetica-Narrow"
        sys.exit(-1)
    
    char = GenEnglishNumAlphabet()
    for ii in xrange( len(char) ):    
        c = char[ii]
        prob = GetMinVppWidthSkewDedectionProbForText( c, sys.argv[3], int(sys.argv[1]), int(sys.argv[2]))
        print c, prob
        sys.stdout.flush()
        
            

