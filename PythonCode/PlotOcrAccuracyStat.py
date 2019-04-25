#!/usr/bin/python
#
# Usage:
#  PlotOcrAccuracyStat <result_csv_file> [<save_image_name>]
#   if <result_csv_file> specified or the file name is '-', it reads from sys.stdin
#  

import sys
from pylab import *

class OcrAccuracyStat:
    def __init__ (self, fileName):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
        else:
            #self.name = fileName;
            self.char = [];
            self.numCorrect = [];
            self.numTotal = [];
            self.correctRate = [];
            
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                #each line has the following format:
                #  <char>, <num_recognized_img>, <num_img>, <prob>                
                if len(elem) >= 4:
                    self.char.append(elem[0])
                    self.numCorrect.append(float(elem[1]))
                    self.numTotal.append(float(elem[2]))
                    self.correctRate.append(float(elem[3]))
                        
            if fileName != '-':
                f.close()    

    def Plot(self, saveImgName):
        ion() # enable pylab's interactivity mode - ioff()
        figure(figsize=(16, 8), dpi=80) # facecolor='w', edgecolor='k'
        ax_num = subplot(111)
        xlabel('Character')
        ylabel('Sample Numbers')
        ax_num.hold(True)   
                       
        ax_rate = twinx()
        ax_rate.hold(True)
        ax_rate.grid(True)
        ylabel('Recognition Accuracy (%)')
        ind = arange(len(self.char))
        
        ax_num.axis([0, len(self.char), 0, max(self.numTotal)]) 
        ax_rate.axis([0, len(self.char), 0, 1.0])                
             
        hNumTotal = ax_num.bar(ind, self.numTotal, color='0.8')  # gray
        hNumCorrect = ax_num.bar(ind, self.numCorrect, color='0.5')        
        #hCorrRate = ax_rate.plot(ind+0.5, self.correctRate, color='r', linestyle='_', linewidth=3.0)        
        hCorrRate = ax_rate.plot(ind+0.5, self.correctRate, 'r-v', linewidth=3.0, markersize=3.0)
        #hCorrRate = ax_rate.plot(ind+0.5, self.correctRate, 'k', linewidth=1.5, markersize=3.0)
        #hCorrRate = ax_rate.plot(ind+0.5, self.correctRate, color='r', linewidth=3.0)
        
        legend( ( hCorrRate[0], hNumCorrect[0], hNumTotal[0] ), ('Accuracy %', 'Correct Sample', 'Total Sample'), 'upper left' )
        
        xticks(ind+0.5, self.char) 
        
        if saveImgName != '-':
            savefig(saveImgName)
        else:       
            show()
        
#============================================================
if __name__ == "__main__":   
    if len(sys.argv) < 2:  # like C
        print "USAGE: PlotOcrAccuracyStat <result_csv_file> [<save_image_name>]"
        sys.exit(-1)
        
    inFileName = sys.argv[1]
    if len(sys.argv) >= 3:
        saveImgName = sys.argv[2]
    else:
        saveImgName = '-'

    result = OcrAccuracyStat(inFileName);        
    result.Plot(saveImgName)
