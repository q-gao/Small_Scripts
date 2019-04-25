#!/usr/bin/python
#
# Common routines for studying font
#
import os
import Image
from pylab import *
import numpy as np
import matplotlib.patches as mpatches  # for drawing things like rectangles (considered a patch)
from matplotlib.collections import PatchCollection

if os.name == 'posix':
    IMAGEMAGICK_INTERMED_IMG_FILE = '/tmp/FontStudy_Imagemagick_tmp_file.gif'
else:
    IMAGEMAGICK_INTERMED_IMG_FILE = 'FontStudy_Imagemagick_tmp_file.gif'       

#============================================================================================
# Max Vertical Projection Profile Hole based Skew Detection
#============================================================================================
def GetMaxVppHoleSkewDedectionProbForText (  text,
                                       fontName, 
                                       rotation_max, ratation_step = 1):
    # DESCRIPTION:
    #  rotation from -rotation_max to ratation_max
    #
    # RETURN:
    #    0      : can't be detected
    #   >0 & < 1: partially detected (= 1/N where N is the number of rotation angles with the min
    #             HPP(Horizontal Proj Profile; degree 0 is one of them)
    #    1      : can be detected
    
    maxVppHoleWid = GetTextVppInsideHoleWidth(text, fontName, 0)
    maxVppHoleWidAngle = [0]
    fZeroDegreeOut = 0
    
    rotation = ratation_step
    while rotation <= rotation_max:
        # nmhw = new max hole width
        nmhw = UpdateMaxVppHoleTable(text, fontName, rotation, maxVppHoleWid, maxVppHoleWidAngle)
        if nmhw > maxVppHoleWid:
            maxVppHoleWid = nmhw
            fZeroDegreeOut = 1
        rotation += ratation_step
        
    rotation = -ratation_step
    while rotation >= -rotation_max:
        nmhw = UpdateMaxVppHoleTable(text, fontName, rotation, maxVppHoleWid, maxVppHoleWidAngle)
        if nmhw > maxVppHoleWid:
            maxVppHoleWid = nmhw
            fZeroDegreeOut = 1 
        rotation -= ratation_step
        
    if fZeroDegreeOut == 0:
        if len(maxVppHoleWidAngle) == 1:
            return 1
        
        return 1.0 / float( len(maxVppHoleWidAngle))
    else:
        return 0

def UpdateMaxVppHoleTable(text, fontName, rotation, maxVppHoleWid, maxVppHoleWidAngle):
    # RETURN:
    #   the new max VPP hole width
    
    vppHoleWid = GetTextVppInsideHoleWidth(text, fontName, rotation)
    if vppHoleWid > maxVppHoleWid:
        maxVppHoleWidAngle = [rotation]
        return vppHoleWid
    
    if vppHoleWid == maxVppHoleWid:
        maxVppHoleWidAngle.append(rotation)
        
    return maxVppHoleWid


def GetTextVppInsideHoleWidth(text, fontName, rotation):
    cmdHead = 'convert -background black -fill white  -pointsize 64 -font '
    
    cmd =  cmdHead + fontName + ' -rotate ' + str(rotation) + ' label:' + text + ' ' + IMAGEMAGICK_INTERMED_IMG_FILE
#    print cmd
    os.system(cmd)
        
    vpp = GetVerticalProjectProfile(IMAGEMAGICK_INTERMED_IMG_FILE)
    return InsideHoleWidth(vpp) 

#============================================================================================
# Min Horizontal Projection Profile based Skew Detection
#============================================================================================    
def GetHppSkewDedectionProbForText (  text,
                                       fontName, 
                                       rotation_max, ratation_step = 1):
    return GetMinPpLengthSkewDedectionProbForText(text, fontName, rotation_max, 
                                                  GetTextHppHeight, ratation_step)

def GetMinVppWidthSkewDedectionProbForText (  text,
                                       fontName, 
                                       rotation_max, ratation_step = 1):
    return GetMinPpLengthSkewDedectionProbForText(text, fontName, rotation_max, 
                                                  GetTextVppWidth, ratation_step)
    
def GetMinPpLengthSkewDedectionProbForText (  text,
                                       fontName, 
                                       rotation_max, getPpLenFunc, ratation_step = 1):
    # DESCRIPTION:
    #  rotation from -rotation_max to ratation_max
    #
    # RETURN:
    #    0      : can't be detected
    #   >0 & < 1: partially detected (= 1/N where N is the number of rotation angles with the min
    #             HPP(Horizontal Proj Profile; degree 0 is one of them)
    #    1      : can be detected
    
#    minPpLen = GetTextHppHeight(text, fontName, 0)
    minPpLen = getPpLenFunc(text, fontName, 0)    
    minPpLenAngle = [0]
    fZeroDegreeOut = 0
    
    rotation = ratation_step
    while rotation <= rotation_max:
        nmhh = UpdateMinPpLengthTable(text, fontName, rotation, minPpLen, minPpLenAngle, getPpLenFunc)
        if nmhh < minPpLen:
            minPpLen = nmhh
            fZeroDegreeOut = 1
        rotation += ratation_step
        
    rotation = -ratation_step
    while rotation >= -rotation_max:
        nmhh = UpdateMinPpLengthTable(text, fontName, rotation, minPpLen, minPpLenAngle, getPpLenFunc)
        if nmhh < minPpLen:
            minPpLen = nmhh
            fZeroDegreeOut = 1 
        rotation -= ratation_step
        
    if fZeroDegreeOut == 0:
        if len(minPpLenAngle) == 1:
            return 1
        
        return 1.0 / float( len(minPpLenAngle))
    else:
        return 0

def UpdateMinPpLengthTable(text, fontName, rotation, minPpLen, minPpLenAngle, getPpLenFunc):
    # RETURN:
    #   the new min HPP height
    
    #ppLen = GetTextHppHeight(text, fontName, rotation)
    ppLen = getPpLenFunc(text, fontName, rotation)
    if ppLen < minPpLen:
        minPpLenAngle = [rotation]
        return ppLen
    
    if ppLen == minPpLen:
        minPpLenAngle.append(rotation)
        
    return minPpLen
    
def EstTextHeightViaHppAverage(text, fontName, txtRotMax, hppAngleMax):
    # CONSTRAINTS
    #   txtRotMax and hppAngleMax should be integers
    #   angelStep is 1 (integer)
    # RETURN:
    #   [heights for angle in range(txtAngel1, txtAngel2 + angelStep)]
    #
    
    #TODO: relax the constraints
    #
    angelStep = 1
    # generate rotated text
    rotAngle2 = txtRotMax + hppAngleMax
    rotAngle1 = - rotAngle2
    
    h = []
    ra = rotAngle1
    while ra <= rotAngle2:
        h.append( GetTextHppHeight(text, fontName, ra) )
        
        ra += angelStep
    
    txtHght = []   
    numPrj =  float(hppAngleMax + hppAngleMax + 1)
    for ii in xrange(hppAngleMax, len(h) - hppAngleMax):
        sumh = 0
        for p in xrange( ii - hppAngleMax, ii + hppAngleMax + 1):
            sumh += h[p]
        txtHght.append( float(sumh)/numPrj )
           
    return txtHght
        
def GetTextHppHeight(text, fontName, rotation):
    cmdHead = 'convert -background black -fill white  -pointsize 64 -font '
    
    cmd =  cmdHead + fontName + ' -rotate ' + str(rotation) + ' label:' + text + ' ' + IMAGEMAGICK_INTERMED_IMG_FILE
#    print cmd
    os.system(cmd)
        
    hpp = GetHorizontalProjectProfile(IMAGEMAGICK_INTERMED_IMG_FILE)
    return WidthWithoutLeftRightMargin(hpp)    

def GetTextVppWidth(text, fontName, rotation):
    cmdHead = 'convert -background black -fill white  -pointsize 64 -font '
    
    cmd =  cmdHead + fontName + ' -rotate ' + str(rotation) + ' label:' + text + ' ' + IMAGEMAGICK_INTERMED_IMG_FILE
#    print cmd
    os.system(cmd)
        
    vpp = GetVerticalProjectProfile(IMAGEMAGICK_INTERMED_IMG_FILE)
    return WidthWithoutLeftRightMargin(vpp)     
           
def GetCharAspectRatio(char, fontName):
    # See class method in http://code.activestate.com/recipes/52304-static-methods-aka-class-methods-in-python/
    # RETURN:
    #   -1 : if no char in the image
    cmd = 'convert -background black -fill white -font ' + fontName + ' -pointsize 64 label:' + char + ' ' + IMAGEMAGICK_INTERMED_IMG_FILE
    print cmd
    os.system(cmd)
    
    i = Image.open(IMAGEMAGICK_INTERMED_IMG_FILE)
    bbox = i.getbbox()
    
    #TODO: the file is locked by Image.open
    #cmd = 'rm ' + IMAGEMAGICK_INTERMED_IMG_FILE
    #print cmd
    #os.system(cmd)
    
    if len(bbox) < 4:
        return -1
    
    return float((bbox[2] - bbox[0])) / float((bbox[3] - bbox[1]))

def GetCharPortionPercentage(char, fontName, rotate = '0'):
    # See class method in http://code.activestate.com/recipes/52304-static-methods-aka-class-methods-in-python/
    # RETURN:
    #   -1 : if no char in the image
    cmd = 'convert -background black -fill white -font ' + fontName + ' -rotate ' + rotate + ' -pointsize 64 label:' + char + ' ' + IMAGEMAGICK_INTERMED_IMG_FILE
    print cmd
    os.system(cmd)
    
    i = Image.open(IMAGEMAGICK_INTERMED_IMG_FILE)
    bbox = i.getbbox()
    
    #TODO: the file is locked by Image.open
    #cmd = 'rm ' + IMAGEMAGICK_INTERMED_IMG_FILE
    #print cmd
    #os.system(cmd)
    
    if len(bbox) < 4:
        return []
    
    return [ float(bbox[1]) / float(i.size[1]),
             float(bbox[3] - bbox[1]) / float(i.size[1]),
             float(i.size[1] - bbox[3]) / float(i.size[1])]

def GetVerticalProjectProfile (imgFile, backgroundColor = 0):
	img = Image.open(imgFile)
	
	d = img.load()
	
	hpp = []	
	for cc in xrange(img.size[0]):
		cnt = 0
		for rr in xrange(img.size[1]):
			if d[cc, rr] != backgroundColor:
				cnt += 1
		hpp.append(cnt)
	
	return hpp

def GetHorizontalProjectProfile (imgFile, backgroundColor = 0):
	img = Image.open(imgFile)
	
	d = img.load()
	
	hpp = []
	for rr in xrange(img.size[1]):
		cnt = 0
		for cc in xrange(img.size[0]):
			if d[cc, rr] != backgroundColor:
				cnt += 1
		hpp.append(cnt)
	
	return hpp	

def WidthWithoutLeftRightMargin (hpp):
    fDot = 0
    ll = len(hpp)
    for ii in xrange(ll):
        if hpp[ii] != 0:
            leftMargin = ii
            fDot = 1
            break
        
    if fDot == 0:
        return 0 
    else:
        fDot = 0
        if leftMargin + 2 < len(hpp):
            for ii in xrange(len(hpp) - 1, leftMargin, -1):
                if hpp[ii] != 0:
                    fDot = 1
                    rightMargin = ll - 1 - ii 
                    break   
        if fDot == 0:
            return 1
        else:
            return ll - leftMargin -rightMargin

def InsideHoleWidth (vpp):
    # Return the width of holes inside a [vertical] projection profile
    wid = 0
    st = 0
    for ii in xrange( len(vpp) ):
        if st == 0:
            if vpp[ii] != 0:
                st = 1
        elif st == 1:
            if vpp[ii] == 0:
                st = 2
                w = 1
        else: # st == 2
            if vpp[ii] != 0:
                wid += w
                st = 1
            else:
                w += 1
    
    return wid
        	
def GenEnglishNumAlphabet():
    char = []
    for ii in xrange(ord('0'), ord('9') + 1):
        char.append(chr(ii))    
    for ii in xrange(ord('A'), ord('Z') + 1):
        char.append(chr(ii))        
    for ii in xrange(ord('a'), ord('z') + 1):
        char.append(chr(ii))
        
    return char
        
def GenEnglishAlphabet():
    char = []
    
    for ii in xrange(ord('A'), ord('Z') + 1):
        char.append(chr(ii))       
    for ii in xrange(ord('a'), ord('z') + 1):
        char.append(chr(ii))
        
    return char    
              
#===============================================================================
# CC (Connected Component) detection
#===============================================================================
def DetectLeftRightCCFromImage (imgFile, backgroundColor = 0):
    img = Image.open(imgFile)
    
    d = img.load()
    
    # Left CC
    #=================================================
    # Found a non-background pixel
    foundSeed = 0
    for x in xrange(img.size[0]):  # From left to right
        for r in xrange(img.size[1]-1, 0, -1): # from botthom to better handle 'i' & 'j'
            if d[x,r] != backgroundColor:
                foundSeed = 1
                break
        if foundSeed:
            break
    
    if foundSeed == 0:
        return [[], []]
    
    ccLeft = DetectCCFromSeed(img, x, r, backgroundColor)
    
    # Right CC if there is one
    #=====================================================
    foundSeed = 0
    for x in xrange(img.size[0]-1, 0, -1):  # from right to left
        for r in xrange(img.size[1]-1, 0, -1): # from botthom to better handle 'i' & 'j'
            if d[x,r] != backgroundColor:
                foundSeed = 1
                break
        if foundSeed:
            break
    
    if foundSeed == 0 or ccLeft[r, x] == 1: # right seed already in the left CC
        return [ccLeft, []]
    
    ccRight = DetectCCFromSeed(img, x, r, backgroundColor)
       
    return [ccLeft, ccRight]

def DetectLeftCCFromImage (imgFile, backgroundColor = 0):
    img = Image.open(imgFile)
    
    d = img.load()
    # Found a non-background pixel
    foundSeed = 0
    for x in xrange(img.size[0]):  # From left to right
        for r in xrange(img.size[1]-1, 0, -1): # from botthom to better handle 'i' & 'j'
            if d[x,r] != backgroundColor:
                foundSeed = 1
                break
        if foundSeed:
            break
    
    if foundSeed == 0:
        return []
    
    cc = DetectCCFromSeed(img, x, r, backgroundColor)
    return cc

def DetectRightCCFromImage (imgFile, backgroundColor = 0):
    img = Image.open(imgFile)
    
    d = img.load()
    # Found a non-background pixel
    foundSeed = 0
    for x in xrange(img.size[0]-1, 0, -1):  # from right to left
        for r in xrange(img.size[1]-1, 0, -1): # from botthom to better handle 'i' & 'j'
            if d[x,r] != backgroundColor:
                foundSeed = 1
                break
        if foundSeed:
            break
    
    if foundSeed == 0:
        return []
    
    cc = DetectCCFromSeed(img, x, r, backgroundColor)
    return cc        
    
def DetectCCFromSeed (img, seedX, seedY, backgroundColor = 0):
    # DESCRIPTION:
    #    CC = Connected Component: defined by non-background pixels 
    # Input:
    #    img: Image object created by PIL
    # RETURN:
    #    A numpy array
    #
    #==============================================================
     
    # x in image = column in numpy (MATLAB)
    #   img[x, y] <=> numpy[y, x]
    cc = zeros( (img.size[1], img.size[0]), dtype=int8)
    imgData = img.load()
    
    if imgData[seedX, seedY] == backgroundColor: #######
        return cc
    cc[seedY, seedX] = 1
            
    seed = [[seedX, seedY]]
    
    while(len(seed) > 0):
        s = seed.pop(0)
        
        for x in xrange( max(0, s[0]-1), min(s[0] + 2, img.size[0]) ): #NOTE: +2 instead of +1
            for y in xrange( max(0, s[1]-1), min(s[1] + 2, img.size[1]) ): #NOTE: +2 instead of +1 
                if x == s[0] and y == s[1]:
                    continue
                if cc[y, x] == 1: # the neighbor already in the CC
                    continue
                
                if imgData[x,y] != backgroundColor: #for non-background neighbors that are not in the CC
                    seed.append([x, y])
                    cc[y, x] = 1
        
    return cc

#TODO: figure out why figure and axies not working
#
#def BwScaleNumpyMatrix (fig, ax, npm, saveFigName = None):
#    #ARGUMENTS:
#    #  npm: numpy matrix whose pixels have value [0,1]
#    
#    #ax = axes([0,0,i.size[0],i.size[1]])
#    numRow = len(npm)  # num of rows
#    if numRow < 1:
#        return
#    numCol = len(npm[0])  # num of column
#    
#    #--------------------------------------
#    for c in xrange(numCol):
#        for r in xrange(numRow):
#            y = numRow - r - 1
#          
#            if npm[r, c] > 0: # non-background
#                fc = 1.0
#            else:
#                fc = 0.0
#            p = mpatches.Rectangle((c,y), 1, 1, 
#                           facecolor = str(fc),  
#                           edgecolor = str(1 - fc))
#
#            #fig.gca().add_patch(p)
#            ax.add_patch(p)
#   
#    #fig.gca().axis([0, numCol, 0, numRow])     
#    ax.axis([0, numCol, 0, numRow])
#    if saveFigName != None:               
#        fig.savefig(saveFigName)   
        
def BwScaleNumpyMatrix (npm, saveFigName = None):
    #ARGUMENTS:
    #  npm: numpy matrix whose pixels have value [0,1]
    
    #ax = axes([0,0,i.size[0],i.size[1]])
    numRow = len(npm)  # num of rows
    if numRow < 1:
        return
    numCol = len(npm[0])  # num of column
    
    figure()        
    hold(True)
    #--------------------------------------
    for c in xrange(numCol):
        for r in xrange(numRow):
            y = numRow - r - 1
          
            if npm[r, c] > 0: # non-background
                fc = 1.0
            else:
                fc = 0.0
            p = mpatches.Rectangle((c,y), 1, 1, 
                           facecolor = str(fc),  
                           edgecolor = str(1 - fc))

            gca().add_patch(p)
   
    gca().axis([0, numCol, 0, numRow])     
    if saveFigName == None:               
        show()
    else:
        savefig(saveFigName)    
        
def GrayScaleDotMatrixImage (imgFileName, saveFigName = None):
    ''' TODO: handle images other than GIF generated from text by ImageMagicK 
    '''
    i = Image.open(imgFileName)
    d = i.load()
    
    figure()
    #ax = axes([0,0,i.size[0],i.size[1]])
    hold(True)
    extrm = i.getextrema()  # min & max pixel value
    
    # Steps to draw rectangles: create patch object & then add it to the figure
    # Method 1:
    #   see #http://www.mail-archive.com/matplotlib-users@lists.sourceforge.net/msg08387.html
    # Method 2 (faster):
    #      see http://matplotlib.sourceforge.net/examples/api/artist_demo.html    
    
    # Method 1 (SLOWER)
    #--------------------------------------
    for x in xrange(i.size[0]):
        for r in xrange(i.size[1]):
            y = i.size[1] - r - 1
          
            edgeFace = float(d[x, r]) / float(extrm[1])
                      
            p = mpatches.Rectangle((x,y), 1, 1, 
                           facecolor = str(1-edgeFace),  
                           edgecolor = str(edgeFace))

            gca().add_patch(p)

#    # Method 2 (FASTER)
#    #--------------------------------------    
#    patchList = []
#    faceColors = []
#    edgeColors = []
#    for x in xrange(i.size[0]):
#        for r in xrange(i.size[1]):
#            y = i.size[1] - r - 1
#          
#            grayFace = float(d[x, r]) / float(extrm[1])
#            faceColors.append(grayFace)
#            edgeColors.append(1 - grayFace)
#
#            p = mpatches.Rectangle((x,y), 1, 1)
#                       
#            patchList.append(p)
#            
#    collection = PatchCollection(patchList, cmap=matplotlib.cm.jet, #matplotlib.cm.gray,
#                                             alpha=0.7)
#        
#    #TODO: how to set edge color
#    collection.set_array(np.array(faceColors))
##    collection.set_facecolors(faceColors)   #only one facecolor
##    collection.set_edgecolors(edgeColors)       
#    gca().add_collection(collection)    
    
    
    gca().axis([0, i.size[0], 0, i.size[1]])     
    if saveFigName == None:               
        show()
    else:
        savefig(saveFigName)

def BwScaleDotMatrixImage (imgFileName, saveFigName = None):
    ''' TODO: handle images other than GIF generated from text by ImageMagicK 
    '''
#    i = Image.open(imgFileName)
#    d = i.load()
#    
#    figure()
#    #ax = axes([0,0,i.size[0],i.size[1]])
#    hold(True)
#    extrm = i.getextrema()  # min & max pixel value
#    
#    # Steps to draw rectangles: create patch object & then add it to the figure
#    # Method 1:
#    #   see #http://www.mail-archive.com/matplotlib-users@lists.sourceforge.net/msg08387.html
#    # Method 2 (faster):
#    #      see http://matplotlib.sourceforge.net/examples/api/artist_demo.html    
#    
#    # Method 1 (SLOWER)
#    #--------------------------------------
#    for x in xrange(i.size[0]):
#        for r in xrange(i.size[1]):
#            y = i.size[1] - r - 1
#                    
#            # Simple binarization method
#            if d[x, r] > 0:
#                grayFace = 0.0
#            else:
#                grayFace = 1.0
#            
#            p = mpatches.Rectangle((x,y), 1, 1, 
#                           facecolor = str(grayFace),  
#                           edgecolor = str(1 - grayFace))
#
#            gca().add_patch(p)
#
##    # Method 2 (FASTER)
##    #--------------------------------------    
##    patchList = []
##    faceColors = []
##    edgeColors = []
##    for x in xrange(i.size[0]):
##        for r in xrange(i.size[1]):
##            y = i.size[1] - r - 1
##          
##            grayFace = float(d[x, r]) / float(extrm[1])
##            faceColors.append(grayFace)
##            edgeColors.append(1 - grayFace)
##
##            p = mpatches.Rectangle((x,y), 1, 1)
##                       
##            patchList.append(p)
##            
##    collection = PatchCollection(patchList, cmap=matplotlib.cm.jet, #matplotlib.cm.gray,
##                                             alpha=0.7)
##        
##    #TODO: how to set edge color
##    collection.set_array(np.array(faceColors))
###    collection.set_facecolors(faceColors)   #only one facecolor
###    collection.set_edgecolors(edgeColors)       
##    gca().add_collection(collection)    
#    
#    
#    gca().axis([0, i.size[0], 0, i.size[1]])     
#    if saveFigName == None:               
#        show()
#    else:
#        savefig(saveFigName)
    BwScaleDotMatrixImage_NoShow(imgFileName, saveFigName)
    if saveFigName == None:               
        show()
    
    
def BwScaleDotMatrixImage_NoShow (imgFileName, saveFigName = None):
    ''' TODO: handle images other than GIF generated from text by ImageMagicK 
    '''
    i = Image.open(imgFileName)
    d = i.load()
    
    figure()
    #ax = axes([0,0,i.size[0],i.size[1]])
    hold(True)
    extrm = i.getextrema()  # min & max pixel value
    
    # Steps to draw rectangles: create patch object & then add it to the figure
    # Method 1:
    #   see #http://www.mail-archive.com/matplotlib-users@lists.sourceforge.net/msg08387.html
    # Method 2 (faster):
    #      see http://matplotlib.sourceforge.net/examples/api/artist_demo.html    
    
    # Method 1 (SLOWER)
    #--------------------------------------
    for x in xrange(i.size[0]):
        for r in xrange(i.size[1]):
            y = i.size[1] - r - 1
                    
            # Simple binarization method
            if d[x, r] > 0:
                grayFace = 0.0
            else:
                grayFace = 1.0
            
            p = mpatches.Rectangle((x,y), 1, 1, 
                           facecolor = str(grayFace),  
                           edgecolor = str(1 - grayFace))

            gca().add_patch(p)

#    # Method 2 (FASTER)
#    #--------------------------------------    
#    patchList = []
#    faceColors = []
#    edgeColors = []
#    for x in xrange(i.size[0]):
#        for r in xrange(i.size[1]):
#            y = i.size[1] - r - 1
#          
#            grayFace = float(d[x, r]) / float(extrm[1])
#            faceColors.append(grayFace)
#            edgeColors.append(1 - grayFace)
#
#            p = mpatches.Rectangle((x,y), 1, 1)
#                       
#            patchList.append(p)
#            
#    collection = PatchCollection(patchList, cmap=matplotlib.cm.jet, #matplotlib.cm.gray,
#                                             alpha=0.7)
#        
#    #TODO: how to set edge color
#    collection.set_array(np.array(faceColors))
##    collection.set_facecolors(faceColors)   #only one facecolor
##    collection.set_edgecolors(edgeColors)       
#    gca().add_collection(collection)    
    
    
    gca().axis([0, i.size[0], 0, i.size[1]])     
    if saveFigName != None:               
        savefig(saveFigName)
                        
def ColorScaleDotMatrixImage (imgFileName, saveFigName = None):
    ''' TODO:
          * Why not working on Linux (fine on Windows) 
          * handle images other than GIF generated from text by ImageMagicK 
    '''
    i = Image.open(imgFileName)
    d = i.load()
    
    figure()
    #ax = axes([0,0,i.size[0],i.size[1]])
    hold(True)
    extrm = i.getextrema()  # min & max pixel value
    
    patchList = []
    faceColors = []
    #edgeColors = []
    for x in xrange(i.size[0]):
        for r in xrange(i.size[1]):
            y = i.size[1] - r - 1
          
            #grayFace = 100.0 * float(d[x, r]) / float(extrm[1])
            grayFace = float(d[x, r]) / float(extrm[1])
            faceColors.append(grayFace)
            #edgeColors.append(1 - grayFace)

            p = mpatches.Rectangle((x,y), 1, 1)
                       
            patchList.append(p)
            
    collection = PatchCollection(patchList, cmap=matplotlib.cm.jet, #matplotlib.cm.gray,
                                             alpha=0.7)        
    #TODO: how to set edge color
    collection.set_array(np.array(faceColors))      
    gca().add_collection(collection)    
    
    
    gca().axis([0, i.size[0], 0, i.size[1]])     
    
    if saveFigName == None:               
        show()
    else:
        savefig(saveFigName)        
        