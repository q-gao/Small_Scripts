#!/usr/bin/python

import sys
from pylab import *

class PpEstCharSize: # Projection Profiled based Char Size
    maxNumLines = 0
    lineColors = ['#00ff00', '#008000', '#004000', 'k', 'b', '#ff0000', '#800000', '#400000', 'm', 'c']    
    def __init__ (self, fileName):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
            sys.exit(-1)
        else:
            self.name = fileName;
            # head line
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                l = len(elem)
                if l < 2:
                    continue
                numAngle = l - 1
                self.angles = []
                self.charHeight = []                
                for ii in xrange(1, l):
                    self.angles.append(int(elem[ii]))  # NOTE: assume angles in integers
                    self.charHeight.append([])                
                break 

            self.chars = []
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                l = len(elem)                
                if l != numAngle + 1: # Should NOT happen
                    continue                
                self.chars.append(elem[0])
                for ii in xrange(1, l):
                    self.charHeight[ii - 1].append(float(elem[ii]))
                        
            if fileName != '-':
                f.close()
                
#    def Print(self):
#        print self.angles
#        print self.chars
#        
#        for a in xrange( len(self.charHeight) ):
#            print self.charHeight[a]                    

    def Plot(self, angleStep):
        #ion() # enable pylab's interactivity mode - ioff()
        # WEIRD: commenting out figure fixes the show() not showing the window problem even though
        #        savefig always works. After that, everything is OK even after removing the comment!!!
        figure(figsize=(16, 8), dpi=80) # facecolor='w', edgecolor='k'
        
        ax_height = subplot(111)  
        xlabel('Character')
        ylabel('Est Char Height')
        ax_height.hold(True)   
        ax_height.grid(True)        
        
        hLines = []
        hLineLabel = []
        idxLine = 0
        ind = arange(len(self.chars))         
        for idxAngle in xrange(0, len(self.angles), angleStep):
            if idxLine >= PpEstCharSize.maxNumLines:
                print "Not enough line colors defined in PpEstCharSize"
                break

            hLines.append(
                          ax_height.plot(ind + 0.5, self.charHeight[idxAngle],
                                         PpEstCharSize.lineColors[idxLine],
                                         linewidth=1.5, markersize=3.0)[0]
                          )
            hLineLabel.append(str(self.angles[idxAngle]))
            idxLine += 1
                    
        legend(hLines, hLineLabel, 'upper left')        
       
        xticks(ind + 0.5, self.chars)
        #fig.savefig('/tmp/t.png')  #DDDDDDDDDDDDDDD
        show()  

PpEstCharSize.maxNumLines = len(PpEstCharSize.lineColors)

if __name__ == '__main__':    
    if len(sys.argv) < 2:
        d = PpEstCharSize('-')
    else:
        d = PpEstCharSize(sys.argv[1])        
    d.Plot(2)


                    
