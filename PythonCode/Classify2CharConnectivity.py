#!/usr/bin/python
#
#  USAGE:
#    Classify2CharConnectivity.py <font_name> <out_root_dir> [<1st_char_start>, <1st_char_end>, <2nd_char_start>, <2nd_char_end>]
#
#  Output in <out_root_dir>
#   <font_name>
#       gap_0:  no gap between the 2 chars
#       gap_1:  gap between the 2 chars <= 1 pixel and > 0
#       gap_2:  gap between the 2 chars <= 2 pixel and > 1
#       gap_3
#       gap_3+

import os
import os.path
import sys
from CalcMinCCGap import *

class Classify2CharConnectivity:
    c_subDir = ['gap_0', 'gap_1', 'gap_2', 'gap_3', 'gap_3+']              
    def Run (self, fontName, outRootDir, char1Start, char1End, char2Start, char2End):
        self.PrepareDir(outRootDir, fontName)
        
        for ascii1 in xrange( ord(char1Start), ord(char1End) + 1):
            char1 = chr(ascii1)
	    if ascii1 >= ord('A') and ascii1 <= ord('Z'):
		char1_f = char1 + '_'
	    else:
		char1_f = char1

            for ascii2 in xrange( ord(char2Start), ord(char2End) + 1):
                char2 = chr(ascii2)
	        if ascii2 >= ord('A') and ascii2 <= ord('Z'):
		   char2_f = char2 + '_'
	        else:
		   char2_f = char2                
                # generate the text image
                text = char1 + char2
                outImgFile = self.outRootDir + os.sep + char1_f + char2_f + '.gif'
                # pointsize 69 => 64 pixel height on my Ubuntu 10.04
                cmd = 'convert -background black -fill white -font %(font)s -pointsize 69 label:%(text)s %(outImg)s' % \
                    {'font': fontName, 'text': text, 'outImg': outImgFile}
                print cmd
                os.system(cmd)
                
                # calculate the gap between the two characters
                gap = CalcMinCCGapInImage(outImgFile)
                ii =  int(gap)
                if gap - ii > 0:
                    ii += 1
                if ii >= len( Classify2CharConnectivity.c_subDir ):
                    ii = len(Classify2CharConnectivity.c_subDir) - 1
                    
                destDir = self.outRootDir + os.sep + Classify2CharConnectivity.c_subDir[ii]
                
                cmd = 'mv ' + outImgFile + ' ' + destDir
                print cmd
                os.system(cmd)
                
    def PrepareDir (self, outRootDir, fontName):
        self.outRootDir = os.path.dirname(outRootDir + os.sep) + os.sep + fontName # dirname('/a') => '/' UNDESIRABLE
                                                                             # dirname('/a/') => '/a' DESIRABLE 
     
        if not os.path.exists(outRootDir):
            cmd = 'mkdir ' + outRootDir
            print cmd
            os.system(cmd)
                        
        if not os.path.exists(self.outRootDir):
            cmd = 'mkdir ' + self.outRootDir
            print cmd
            os.system(cmd)
        
        for ii in xrange( len(Classify2CharConnectivity.c_subDir) ):
            sd = self.outRootDir + os.sep + Classify2CharConnectivity.c_subDir[ii]
            
            if not os.path.exists(sd):
                cmd = 'mkdir ' + sd
                print cmd
                os.system(cmd)                    
    
#====================================================
if __name__ == '__main__':
    import sys

    if len(sys.argv) < 3:
		print "USAGE: Classify2CharConnectivity.py <font-name> <out_root_dir>"
		sys.exit(-1)


    classifier = Classify2CharConnectivity()

    classifier.Run(sys.argv[1], sys.argv[2], 'A', 'Z', 'A','Z')    
    classifier.Run(sys.argv[1], sys.argv[2], 'A', 'Z', 'a','z')
    classifier.Run(sys.argv[1], sys.argv[2], 'a', 'z', 'a','z')


    
