#!/usr/bin/python

# bar stacked: 
#
# clf(): clear fig; close(): close a fig; figure(): start a new figure
# Matplotlib HOW-TO: http://matplotlib.sourceforge.net/faq/howto_faq.html
#   E.g., save to PDF etc.

import sys
from pylab import *

class OcrCandidateCostData:
    # Constant
    maxNumCandidates = 7
    barColors = ['#00ff00', '#008000', '#004000', '#ffff00', '#808000', '#404040', 'm']
    # Color here
    def __init__ (self, fileName):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
        else:       
            self.data = {}    
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                # Each line has the following format:
                #  <char>, <image_name>, <char_cost>, <candidate_1_cost>, [<candidate_2_cost> [, ...]]
                numElem = len(elem)
                char = elem[0]             
                if numElem  >= 4:
                    if char not in self.data:
                        self.data[ char ] = []
                        for ii in xrange(1 + OcrCandidateCostData.maxNumCandidates):
                            self.data[ char ].append([])
                    
                    for ii in xrange( numElem - 2 ):
                        if int(elem[ii + 2]) >= 0:
                            self.data[char][ii].append(int(elem[ii + 2]) + 1)  ##### Cost + 1
                        else:
                            self.data[char][ii].append(int(elem[ii + 2]))  ##### Cost + 1
                    
                    if numElem -2 < 1 + OcrCandidateCostData.maxNumCandidates:
                        for ii in xrange(numElem - 2, 1 + OcrCandidateCostData.maxNumCandidates):
                            self.data[char][ii].append(0)
                    
            if fileName != '-':
                f.close()        
                
    def Print (self):
        # Verification code
        for char in self.data.keys():
            print char + ':'
            print '----------------------'
            for rr in xrange(len(self.data[char][0])):
                s = ''
                for cc in xrange(1 + OcrCandidateCostData.maxNumCandidates):
                    s = s + ' ' + str(self.data[char][cc][rr])
                print s                         
    
    def Plot(self, saveImgNamePrefix):
        ion() # enable pylab's interactivity mode - ioff()
       
        legendLabel = []
        for ii in xrange(OcrCandidateCostData.maxNumCandidates):
            legendLabel.append('cand_' + str(ii + 1))    
        legendLabel.append('truth_char')

        aChar = self.data.keys()
        aChar.sort()
        for char in aChar:            
            print 'Processing results for \"' + char + '\"...'    
            legendLine = []
            close()
            figure(figsize=(max (8, 16.0*len(self.data[char][0])/100.0), 7), dpi=80) # facecolor='w', edgecolor='k'               
            #clf()     
            ax_cost = subplot(111)
            xlabel('Image Sample')
            ylabel('Cost + 1')
            title('Character \"'+ char + '\"')
            ax_cost.hold(True)   

            ind = arange(len(self.data[char][0]))

            # Candidate costs         
            legendLine.append(
                              ax_cost.bar(ind, self.data[char][1], color=OcrCandidateCostData.barColors[0])[0] # top candidate
                              )
            btm = zeros(len(self.data[char][0]))               
            # the remaining candidates plotted as stacked bar
            # See http://matplotlib.sourceforge.net/examples/pylab_examples/bar_stacked.html
            #  and http://stackoverflow.com/questions/3211079/interactive-stacked-bar-chart-using-matplotlib-python
            for cc in xrange(2, 1 + OcrCandidateCostData.maxNumCandidates):
                btm = btm + self.data[char][cc - 1]
                legendLine.append(
                                  ax_cost.bar(ind, self.data[char][cc], color=OcrCandidateCostData.barColors[cc - 1], bottom=btm)[0]
                                  ) 
            
            # Cost of the true char
            legendLine.append(
                              ax_cost.plot(ind + 0.5, self.data[char][0], color='r', linewidth=2.0)[0]
                              )
            
            legend( legendLine, legendLabel, 'upper right')
            
            btm = btm + self.data[char][OcrCandidateCostData.maxNumCandidates]            
            ax_cost.axis([0, len(ind), -1, 
                          min(35, max(btm))]  ###### LOOK uses cost 10000 to indicate unlikely candidate??
                         )           
#            xticks(ind+0.5, self.char) 
#            
#            if saveImgName != '-':
#                savefig(saveImgName)
            savefig(saveImgNamePrefix + char + '.png')
                   
            #draw()  # non-blocking show() will block
                    
#============================================================
if __name__ == "__main__":
    
    if len(sys.argv) < 3:  # like C
        print "USAGE: PlotOcrCandidateCostSeq <candidate_cost_file> <save_image_name_prefix>"
        sys.exit(-1)
        
    inFileName = sys.argv[1]
    saveImgNamePrefix = sys.argv[2]

    result = OcrCandidateCostData(inFileName);
    result.Plot(saveImgNamePrefix)
    #result.Print()        
