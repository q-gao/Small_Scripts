#!/usr/bin/python
from  FontStudyTool import *

import sys

if len(sys.argv) < 2:
    print "Usage: BwScaleDotMatrixImage.py <in_image_file> [<out_image_file>]"
    sys.exit(-1)
     
if len(sys.argv) <= 2:
    BwScaleDotMatrixImage(sys.argv[1])    
else:
    BwScaleDotMatrixImage(sys.argv[1], sys.argv[2])




    
