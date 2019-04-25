#!/usr/bin/python
#
#

#from pylab import *
from FontStudyTool import *
import os
import sys
           
def GetCharPairFailingHppSkewDedection (startAscii1, endAscii1, startAscii2, endAscii2,
                                       fontName, 
                                       rotation_max, ratation_step = 1):
    
    badCharPairInfo = []
    for asc1 in xrange(startAscii1, endAscii1 + 1):
        chr1 = chr(asc1)
        for asc2 in xrange(startAscii2, endAscii2 + 1):
            text = chr1 + chr(asc2)
            
            prob = GetHppSkewDedectionProbForText ( text, fontName, rotation_max, ratation_step)
            
            if prob < 1:
                badCharPairInfo.append([text, prob])
                
    return badCharPairInfo

if __name__ == '__main__':      
    if len(sys.argv) < 4:
        print "USAGE: StudySkewDetectionFor2CharCombination.py <rotation_max> <rotation_step> <font_name>"
        print "   rotation specified in clock-wise angle in integers "
        print "   Narrow font on Linux: Helvetica-Narrow"
        sys.exit(-1)
    
    aBadCharPairs = [] 
    aBadCharPairs.append(
                         GetCharPairFailingHppSkewDedection(ord('A'), ord('Z'), ord('A'), ord('Z'), 
                                      sys.argv[3], int(sys.argv[1]), int(sys.argv[2]))
                         )
    aBadCharPairs.append(
                         GetCharPairFailingHppSkewDedection(ord('A'), ord('Z'), ord('a'), ord('z'), 
                                      sys.argv[3], int(sys.argv[1]), int(sys.argv[2]))
                         )    
    aBadCharPairs.append(
                         GetCharPairFailingHppSkewDedection(ord('a'), ord('z'), ord('a'), ord('z'), 
                                      sys.argv[3], int(sys.argv[1]), int(sys.argv[2]))
                         )    

    print "====================================================="
    print "char pair failing HPP skew detection"
    print "====================================================="
    for cc in xrange( len(aBadCharPairs) ):
        for ii in xrange( len(aBadCharPairs[cc]) ):
            print aBadCharPairs[cc][ii]
    

