#!/usr/bin/python
#
# Usage:
#  PlotMultiOcrAccuracyStat.py [<result_csv_file_1> <label_1> [<result_csv_file2> <label_2>...] [<saveImageName>]
#  

import sys
from pylab import *

class OcrAccuracyStat:
    def __init__ (self, fileName, label):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
            sys.exit(-2)
        else:
            self.label = label
            self.char = []
            self.numCorrect = []
            self.numTotal = []
            self.errorRate = []
            
            for line in f:
                elem = line.rstrip().split(',')  # os.linesep could be used in strip
                #each line has the following format:
                #  <char>, <num_recognized_img>, <num_img>, <prob>                
                if len(elem) >= 4: # and not (ord(elem[0]) >= 48 and ord(elem[0]) <= 57) and elem[0] != 'i' and elem[0] != 'q':
                    self.char.append(elem[0])
                    self.numCorrect.append(float(elem[1]))
                    self.numTotal.append(float(elem[2]))
                    self.errorRate.append(1.0 - float(elem[3]))
                        
            if fileName != '-':
                f.close()    
        
class PlotOcrAccuracyStat:
    LINE_COLOR = ['r', 'g', 'b', 'k', 'm', 'c']    
    def __init__ (self):
        ion()   # enable pylab's interactivity mode - ioff()
        figure(figsize=(13, 8), dpi=80) # facecolor='w', edgecolor='k'
        self.ax_num = subplot(111)
        xlabel('Character')
        ylabel('Sample Numbers')
        self.ax_num.hold(True)   
                       
        self.ax_rate = twinx()
        self.ax_rate.hold(True)
        self.ax_rate.grid(True)
        ylabel('Recognition Error Rate (%)')
                
    def Plot (self, aResults, saveImgName):
        if len(aResults) < 1:
            return
        
        if len(aResults) > len(PlotOcrAccuracyStat.LINE_COLOR):
            print "ERROR: not enough colors in PlotOcrAccuracyStat.LINE_COLOR for all the lines"
            sys.exit(-3)
        
        ind = arange(len(aResults[0].char))               
             
        hNumTotal = self.ax_num.bar(ind, aResults[0].numTotal, color='0.65')  # gray
        
        legendLine = []
        legendLabel = []
        for ii in xrange(len(aResults)):
            lineSpec = PlotOcrAccuracyStat.LINE_COLOR[ii] + '-v'
            legendLine.append(
                              self.ax_rate.plot(
                                                ind+0.5, aResults[ii].errorRate, lineSpec, linewidth=1.5, markersize=1.5
                                                )[0]
                              )
            legendLabel.append(aResults[ii].label)
        
        legend(legendLine, legendLabel, 'center right' )        
        
        xticks(ind+0.5, aResults[0].char) 

      
        if saveImgName != '-':
            savefig(saveImgName)
        else:
            show();


#============================================================
if __name__ == "__main__":
    numArg = len(sys.argv)
    if  numArg < 3:
        print "USAGE:"
        print "  PlotMultiOcrAccuracyStat.py [<result_csv_file_1> <label_1> [<result_csv_file2> <label_2>...] [<saveImageName>]"
        sys.exit(-1)

    idxCsv1 = 1    
    if numArg % 2 : # Odd num
        idxCsvLast = numArg - 2
        saveImgName = '-'
    else:
        idxCsvLast = numArg - 3
        saveImgName = sys.argv[numArg - 1]        
        
    result = []
    for ii in xrange(idxCsv1, idxCsvLast + 1, 2):
        result.append( OcrAccuracyStat(sys.argv[ii], sys.argv[ii + 1]) )

             
    fig = PlotOcrAccuracyStat();
    
    fig.Plot(result, saveImgName) 

