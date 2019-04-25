#!/usr/bin/python
from  FontStudyTool import *

import sys

if len(sys.argv) < 2:
    print "Usage: ColorScaleMatrixImage.py <in_image_file> [<out_image_file>]"
    sys.exit(-1)
     
if len(sys.argv) <= 2:
    ColorScaleDotMatrixImage(sys.argv[1])    
else:
    ColorScaleDotMatrixImage(sys.argv[1], sys.argv[2])




    
