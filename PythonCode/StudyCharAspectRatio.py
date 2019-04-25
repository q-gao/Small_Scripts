#!/usr/bin/python
#
# Usage:
# 
# ImagemagicK white on black => GIF => PIL 

import sys
import os
import Image
from pylab import *
from  FontStudyTool import *

# class StudyCharAspectRatio:
#    TMP_FILE_NAME = 'StudyCharAspectRatio_tmp_file.gif'
#    
#    
#    def GetCharAspectRatio(self, char):
#        # See class method in http://code.activestate.com/recipes/52304-static-methods-aka-class-methods-in-python/
#        # RETURN:
#        #   -1 : if no char in the image
#        cmd = 'convert -background black -fill white -font Times-Roman -pointsize 76 label:' + char + ' ' + TMP_FILE_NAME
#        print cmd
#        os.popen(cmd)
#        
#        i = Image.open(TMP_FILE_NAME)
#        bbox = i.getbbox()
#        
#        cmd = 'rm ' + TMP_FILE_NAME
#        print cmd
#        os.popen(cmd)
#        
#        if len(bbox) < 4:
#            return -1
#        
#        return (bbox[3] - bbox[1]) / (bbox[2] - bbox[0])

def GenCharSeq():
    # A - Z: 65 - 90
    seq = []

    for ii in xrange(ord('0'), ord('9') + 1):
         seq.append(chr(ii))
             
    for ii in xrange(ord('A'), ord('Z') + 1):
         seq.append(chr(ii))
         
    for ii in xrange(ord('a'), ord('z') + 1):
         seq.append(chr(ii))
         
    return seq
#
class FontAspectRatio:
    def __init__(self, fontName, charSeq):
        self.fontName = fontName
        self.ar = []
        for ii in xrange(len(charSeq)):
            self.ar.append(
                           GetCharAspectRatio(charSeq[ii], self.fontName)
                           )
            
class PlotFontAspectRatio:
    COLORS = ['#00ff00', '#008000', '#004000', '#ffff00', '#808000', '#404040', 'm']
    def __init__(self, charSeq):
        self.charSeq = charSeq

        ion()  # enable pylab's interactivity mode - ioff()
        figure(figsize=(16, 8), dpi=80)  # facecolor='w', edgecolor='k'
        hold(True)
        grid(True)
        
    def Plot(self, fontAspectRatios):       
        ind = arange(len(self.charSeq))
        # find the min and max of the AR (aspect ratio) for each char
        arMin = []
        arMax = []
        for c in xrange(len(self.charSeq)):
            arMin.append(fontAspectRatios[0].ar[c])
            arMax.append(fontAspectRatios[0].ar[c])
              
        for f in xrange(1, len(fontAspectRatios)):
            for c in xrange(len(self.charSeq)):
                if fontAspectRatios[f].ar[c] < arMin[c]:
                    arMin[c] = fontAspectRatios[f].ar[c]
                    
                if fontAspectRatios[f].ar[c] > arMax[c]:
                    arMax[c] = fontAspectRatios[f].ar[c]
        # arMax to the width of the AR range        
        for c in xrange(len(self.charSeq)):
            arMax[c] -= arMin[c]
        
        bar(ind, arMax, width=0.5, bottom=arMin)
        xticks(ind, self.charSeq)                
            
        # plot a aspect ratio curve per font
        #----------------------------------------------
#        legendLine = []
#        legendLabel = []        
#        for ii in xrange(len(fontAspectRatios)):
#            legendLine.append(
#                              plot(ind, fontAspectRatios[ii].ar, PlotFontAspectRatio.COLORS[ii])[0]
#                              )
#        xticks(ind, self.charSeq)
#        
#        legend(legendLine,
#               [fontAspectRatios[ii].fontName for ii in xrange(len(fontAspectRatios))],
#               'upper left'
#               ) 
        # savefig('fontAspectRatio.png')
        ioff()  # otherwise show() will be non-blocking
        show()
            
#============================================================
if __name__ == "__main__":
    charSeq = GenCharSeq()
    # the following works on my Ubuntu 11 box
    fontNames = [
                'Times-New-Roman',
                 'Arial',
                 # windows fonts
                 #-------------------------------
                 # narrow one
                 "Bernard-MT-Condensed",               
                 'Haettenschweiler',  # really narrow
                 "Onyx-MT",     # even narrower
                 "Agency-FB",
                # regular
                 'Courier-New',  # Windows
                 'Lucida-Console',
                 'Segoe-UI',
                 'Bookman-Old-Style'  # Windows
                 # wide one
                 'Arial-Black',                 
                 'Bondoni-MT-Black',  # really wide                 
                 # Ubuntu fonts
                 #-------------------------------                
#                'Bitstream-Charter-Regular', # Ubuntu 11                 
#                'Helvetica',  # Ubuntu 11                 
#                'DejaVu-Sans-Book'  # Ubuntu 11
                 ]
    
    fars = [FontAspectRatio(fontNames[ii], charSeq) for ii in xrange(len(fontNames))]
    print '# of Fonts = %d' % len(fontNames)
    disp = PlotFontAspectRatio(charSeq)    
    disp.Plot(fars)
    
    
