#!/usr/bin/python
#
# Usage:
#  PlotDetectResults [<result_csv_file> [<result_csv_file> ...]]
#   if no CSV file is specified, it reads from sys.stdin
#  

import sys
from pylab import *

class TextDetectResult:

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
            self.data = [[], [], [], []];
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                for ii in xrange(len(elem)):
                    if ii != 0:
                        self.data[ii].append(float(elem[ii]))
                    else:
                        self.data[ii].append(elem[ii])
                        
            if fileName != '-':
                f.close()
            
    def PrintAverage(self):   
        s = self.name    
  
        for ii in xrange(1, len(self.data)):
            avg = float(sum(self.data[ii])) / len(self.data[ii]) 
            s += (',' + str(avg))
        
        print s
        
class PlotTextDetectResult:
    LINE_COLOR = ['r', 'g', 'b', 'k']    
    def __init__ (self):
        ion()   # enable pylab's interactivity mode - ioff()
        figure(figsize=(20, 16), dpi=80) # facecolor='w', edgecolor='k'
        # in percentage
        subplots_adjust(left=0.05, right=0.95,
                        top=0.95, bottom=0.05,
                        wspace=0.2, hspace=0.15)  # it's a figure method
                               
        ax1 = subplot(311)
        ax1.hold(True)
        ax1.grid(True)
        title('Precision')
#        xlabel('Time(sec)')
        ylabel('Precision')
        
        ax2 = subplot(312)
        ax2.hold(True)
        ax2.grid(True)
        title('Recall')
        ylabel('Recall')

        ax3 = subplot(313)
        ax3.hold(True)
        ax3.grid(True)
        title('F')
        ylabel('F')
        
        self.axes = [ax1, ax2, ax3] # Reverse direction            

    def Plot (self, dectResults):
        for ii in xrange(1, 4):
            self.PlotOneResult(dectResults, ii)
        #draw()  #show() will block
        show();       

    def PlotOneResult (self, dectResults, resultIdx):
        for ii in xrange(0, len(dectResults)):     
            self.axes[resultIdx - 1].plot(xrange(1, len(dectResults[ii].data[resultIdx]) + 1),
                                          dectResults[ii].data[resultIdx],
                                          PlotTextDetectResult.LINE_COLOR[ii])

#============================================================
if __name__ == "__main__":
    import sys
    
    result = []
    if len(sys.argv) > 1:
        for ii in xrange(1, len(sys.argv)):
            result.append(TextDetectResult(sys.argv[ii]))
    else:
        result.append(TextDetectResult('-'))  # read from sys.stdin

    for ii in xrange(0, len(result)): 
        result[ii].PrintAverage();
               
    fig = PlotTextDetectResult();
    
    fig.Plot(result) 

