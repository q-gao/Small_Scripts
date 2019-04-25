#!/usr/bin/python
#
# VisualizeImageSizeVsAccuracy.py <candidate_cost_file> <char_flat.xml>  <char_img_dir_relative_to_char_flat.xml>
#
# candidate_cost_csv_file (one line per char image):
#------------------------------------------------------
#<letter>, <image_name>, <cost_of_letter>, <cost_of_candidate_1> [<cost_of_candidate_2> ...]
#           -1 if <letter> is not recognized (one of the candidate)
#
#http://stackoverflow.com/questions/89228/how-to-call-external-command-in-python
#
#import subprocess
#return_code=subprocess.call(['identify', '/local/mnt/workspace/qgao/MyWork/Projects/Text_Recognition/CharImgsFromLOOKTeam/Flat/014663.bmp'])

#import os
#
import sys
import re
import os
import os.path  #os.path.basename()/dirname()
from pylab import *

def GetImageResolution(imgFile):
    cmd = 'identify ' + imgFile
    out = os.popen(cmd).read()   
#    lines = out.split('\n')    
    m = re.search(r'\s+(\d+)x(\d+)\s+', out)
    if m:
        return [int(m.group(1)), int(m.group(2))]
    else:
        return [-1, -1]

class ImageSizeVsAccuracy:
    LINE_COLOR = ['#00ff00', '#008000', '#a0a000', '#ff0000']
    
    def __init__(self, candCostFile, charXmlFile, charImgRelDir):       
        self.BuildImgName2CharMap(charXmlFile)      
        
        charXmlFile.rstrip('/')     #remove trailing '/' if there is any          
        self.charXmlDir = os.path.dirname(charXmlFile) # Not as good as the perl function
        if self.charXmlDir == '':
            self.charXmlDir = '.'
        self.charImgRelDir = charImgRelDir
        
        # candidate_cost_csv_file (one line per char image):
        #------------------------------------------------------
        #<letter>, <image_name>, <cost_of_letter>, <cost_of_candidate_1> [<cost_of_candidate_2> ...]
        #           -1 if <letter> is not recognized (one of the candidate)
        try:
            f = open(candCostFile, 'r')
        except IOError:
            print 'cannot open ', candCostFile
        else:
            self.mapChar2ImgSizeSeq = {}
            self.mapChar2TopCounts = {}
            for line in f:
                elem = line.rstrip().split(',');  # os.linesep could be used in strip
                
                if len(elem) < 4:
                    continue
                imgFileName = self.charXmlDir + '/' + self.charImgRelDir + '/' + elem[1]
                res = GetImageResolution(imgFileName)
                print elem[1] + ':', res[0], 'x', res[1]
                if res[0] <= 0:
                    continue                    
                imgNumPixels = res[0] * res[1]
                char = elem[0].lower()  ##########  Case insensitive  
                if not self.mapChar2ImgSizeSeq.has_key(char):
                    self.mapChar2ImgSizeSeq[char] = [[], [], [], []]
                    self.mapChar2TopCounts[char] = 0
                
                [matchType, topCnt] = self.GetResultType(elem)    
                self.mapChar2ImgSizeSeq[char][matchType].append(imgNumPixels)
                self.mapChar2TopCounts[char] += topCnt
                            
            f.close()      
              
    def GetResultType(self, elem):
        #RETURN [result_type, ]:
        # result_type:
        #  0 (Excellent): the char is the only top candidate
        #  1 (Good): the char is one of the more than one top candidate
        #  2 (Fair): the char is one of the non-top candidate(s)
        #  3 (Poor): the char is not one of the candidate
        # top_count:
        #  1 : the char is the only top candidate
        # 0 < < 1: the char is one of the top candidates
        #  0:  the char is not the top candidate
        charCost = elem[2]
        if charCost < 0:
            return [3, 0]
        
        topCandCost = elem[3]
                
        matchType = 3  # type of the candidate match 0=match to a top candidate, 2=match to a non-top candidate, 3= no match
        numTopCand = 0
        for ii in xrange(3, len(elem)):
            # Examine match
            if charCost == elem[ii]: # found a match
                if elem[ii] == topCandCost: # top-candidate match
                    matchType = 0;                    
                else: # non-top candidate match                    
                    return [2, 0]
            
            #examine cost transition
            if elem[ii] == topCandCost: # still in top candidate area
                numTopCand += 1
            else: # transition to non-top candidate area
                if matchType == 0:
                    if numTopCand > 1:
                        matchType = 1
        
        if matchType < 2:
            if numTopCand > 1:
                topCnt = 1.0/numTopCand
            else:
                topCnt = 1.0
        else:
            topCnt = 0        
            
        return [matchType, topCnt]
    
    def BuildImgName2CharMap(self, charXmlFile):        
        #<?xml version="1.0" encoding="iso-8859-1"?>
        #    <imagelist>
        #        <image file="001236.bmp" tag="0" />
        #        ...
        #    </imageList>
        try:
            f = open(charXmlFile, 'r')
        except IOError:
            print 'cannot open ', charXmlFile
        else:
            self.mapImgName2Char = {}
            for line in f:
                m = re.search(r'file=\"(.+)\"\s+tag=\"(.+)\"', line)
                if m:
                    self.mapImgName2Char[m.group(1)] = m.group(2).lower()  ##########  Case insensitive                                           
                            
            f.close()

    def Plot(self, saveFigName):
        ion() # enable pylab's interactivity mode - ioff()
        figure(figsize=(16, 8), dpi=80) # facecolor='w', edgecolor='k'
        ax_num = subplot(111)
        xlabel('Character')
        ylabel('Sample Numbers')
        ax_num.hold(True)   
                       
        ax_imgSize = twinx()
        ax_imgSize.hold(True)
        ax_imgSize.grid(True)
        ylabel('Image Size (# pixels)')
        
        # 3rd axis ???
#        ax_accuracy = twinx()
#        ax_accuracy.hold(True)
#        ax_accuracy.grid(True)
#        ax_accuracy.spines['right'].set_position(('axes', 1.2)) # offset the right spine
#        ax_accuracy.set_frame_on(True)
#        ax_accuracy.patch.set_visible(False)
#        for sp in ax_accuracy.spines.itervalues():
#            sp.set_visible(False)
#        ax_accuracy.spines['right'].set_visible(True)        # show the right spine
#        ax_accuracy.set_ylabel('Accuracy (%)')        
        
        chars = sorted(self.mapChar2ImgSizeSeq.keys())
        ind = arange(len(chars))
        
#        ax_num.axis([0, len(self.char), 0, max(self.numTotal)]) 
#        ax_imgSize.axis([0, len(self.char), 0, 1.0])
        numImgs = []
        numTotalCnt = []
        meanImgNumPixel = [[], [], [], []]
                        
        for c in chars:
            n = 0
            for ii in xrange(len(self.mapChar2ImgSizeSeq[c])):
                ll = len(self.mapChar2ImgSizeSeq[c][ii])
                n += ll
                if ll > 0:
                    meanImgNumPixel[ii].append(mean(self.mapChar2ImgSizeSeq[c][ii]))
                else:
                    meanImgNumPixel[ii].append(0)
            
            numImgs.append(n)
            numTotalCnt.append(self.mapChar2TopCounts[c])
                            
                 
        hNumImgs = ax_num.bar(ind, numImgs, color='0.8')  # gray
        ax_num.bar(ind, numTotalCnt, color='0.5')  # gray
        
        hImgNumPixel = []      
        for ii in xrange(len(meanImgNumPixel)):  
            hImgNumPixel.append(
                                ax_imgSize.plot(ind + 0.5, meanImgNumPixel[ii], 
                                                color=ImageSizeVsAccuracy.LINE_COLOR[ii], linewidth=1.5, markersize=3.0)
                                )
        #hCorrRate = ax_rate.plot(ind+0.5, self.correctRate, color='r', linewidth=3.0)
        
        legend((hNumImgs[0], hImgNumPixel[0][0], hImgNumPixel[1][0], hImgNumPixel[2][0], hImgNumPixel[3][0]), 
               ('Total Sample', 'Excellent', 'Good', 'Fair', 'Poor'), 'upper left')
        
        xticks(ind + 0.5, chars) 
        
        if saveFigName != '-':
            savefig(saveFigName)
        else:
            show()        
    
    def Print(self):
#        for k in sorted(self.mapImgName2Char.keys()):
#            print k + ': ' + self.mapImgName2Char[k]
            
        for k in sorted(self.mapChar2ImgSizeSeq.keys()):
            print k + ':' + str(len(self.mapChar2ImgSizeSeq[k][0]))            
            
#============================================================
if __name__ == "__main__":
    if len(sys.argv) < 4:
        print "USAGE: VisualizeImageSizeVsAccuracy.py <candidate_cost_file> <char_flat.xml>  <char_img_dir_relative_to_char_flat.xml> [save_fig_name]"
        sys.exit(-1)
        
    result = ImageSizeVsAccuracy(sys.argv[1], sys.argv[2], sys.argv[3])
    #result.Print()
    
    if len(sys.argv) >= 5:
        result.Plot(sys.argv[4])
    else:
        result.Plot('-')
    
    
