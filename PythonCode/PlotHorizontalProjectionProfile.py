#!/usr/bin/python

from pylab import *
from FontStudyTool import *
import sys

if len(sys.argv) < 2:
    print "USAGE: PlotHorizontalProjectionProfile <imgFile> [<out_img_file>]"
    sys.exit(-1)
    
hpp = GetHorizontalProjectProfile(sys.argv[1])

figure()
plot(hpp)

if len(sys.argv) >= 3:
    savefig(sys.argv[2])
else:
    show()
    

