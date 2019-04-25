#!/usr/bin/python
#
#TODO: this needs some refinement
#
# Usage:
#  PlotXYScatter.py [<result_csv_file> [<result_csv_file> ...]]
#   if no CSV file is specified, it reads from sys.stdin
#  

import sys
from pylab import *

class XySequence:

    def __init__ (self, fileName):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
        else:
            self.name = fileName;
            self.data = [[], []];
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                for ii in xrange(len(elem)):
                    self.data[ii].append(float(elem[ii]))                                            
            if fileName != '-':
                f.close()
                   
class ScatterXySequence:
    LINE_COLOR = ['r', 'g', 'b', 'k']    
    def __init__ (self):
        ion()   # enable pylab's interactivity mode - ioff()
        figure(); # figure(figsize=(20, 16), dpi=80) # facecolor='w', edgecolor='k'

    def Plot (self, xySeq):
        plot(xySeq.data[0], xySeq.data[1], 'x')
        #draw()  #show() will block
        show();       

#============================================================
if __name__ == "__main__":
    import sys
    
    result = []
    if len(sys.argv) > 1:
        for ii in xrange(1, len(sys.argv)):
            result.append(XySequence(sys.argv[ii]))
    else:
        result.append(XySequence('-'))  # read from sys.stdin

              
    fig = ScatterXySequence();

    for ii in xrange(0, len(result)):
        fig.Plot(result[ii]) 

