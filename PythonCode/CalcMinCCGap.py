#!/usr/bin/python
#

from numpy import *
from  FontStudyTool import *

def CalcMinCCGapInImage (imageFile):
    ccLeft, ccRight = DetectLeftRightCCFromImage(imageFile)
    
    # eci = Edge Column Info
    eciLeft = GetRightMostPixelColumnInfo(ccLeft)
    if len(ccRight) <= 0: # there is only one CC
        return 0
    
    eciRight = GetLeftMostPixelColumnInfo(ccRight)
#    edgeLeft = GetRightMostPixel(ccLeft)
#    edgeRight = GetLeftMostPixel(ccRight)
    
    #print eciRight
    numRow = len(eciLeft)
    maxCol = max(eciRight[:,1]) # max column in the right edge
    minDist = numRow + maxCol #sqrt( float(maxCol*maxCol + numRow * numRow) )
    
    for r in xrange(numRow):
        if eciLeft[r, 0] == 0: # not an edge dot
            continue
        
        minDist = CalDotToEdgeTopPortionMinDistance([eciLeft[r, 1],r], eciRight, minDist)
        minDist = CalDotToEdgeBottomPortionMinDistance([eciLeft[r, 1],r], eciRight, minDist)
        
    return minDist - 1

   
def CalDotToEdgeTopPortionMinDistance (dot, edgeColumnInfo, distStart):
    minDist = float(distStart)
    for r in xrange( dot[1], -1, -1):
        if edgeColumnInfo[r, 0] == 0: # not an edge dot
            continue
        
        if dot[1] - r >= minDist:  # no point to try it further
            break
        
        dx = edgeColumnInfo[r, 1] - dot[0] 
        dy = dot[1] - r 
        d = sqrt(float(dx*dx + dy*dy))
        
        if d < minDist:
            minDist = d
            
    return minDist        

def CalDotToEdgeBottomPortionMinDistance (dot, edgeColumnInfo, distStart):
    minDist = float(distStart)
    numRow = len(edgeColumnInfo)
    for r in xrange( dot[1]+1, numRow):
        if edgeColumnInfo[r, 0] == 0: # not an edge dot
            continue
        
        if dot[1] - r >= minDist:  # no point to try it further
            break
        
        dx = edgeColumnInfo[r, 1] - dot[0] 
        dy = dot[1] - r 
        d = sqrt(dx*dx + dy*dy)
        
        if d < minDist:
            minDist = d
            
    return minDist 

def GetRightMostPixelColumnInfo (cc, backgroundColor = 0):
    numRow = len(cc)
    if numRow < 1:
        return []
    
    numCol = len(cc[0])

    edgeColumnInfo = zeros((numRow, 2), dtype=int16)
    
    for r in xrange(numRow): # from botthom to better handle 'i' & 'j'
        for c in xrange( numCol-1, 0, -1):  # from right to left
            if cc[r, c] != backgroundColor:
                edgeColumnInfo[r, 0] = 1 #indicate there is an edge pixel on this row
                edgeColumnInfo[r, 1] = c #indicate the column of the edge pixel                
                break
            
    return edgeColumnInfo

def GetLeftMostPixelColumnInfo (cc, backgroundColor = 0):
    numRow = len(cc)
    if numRow < 1:
        return []
    
    numCol = len(cc[0])

    edgeColumnInfo = zeros((numRow, 2), dtype=int16)
    
    for r in xrange(numRow): # from botthom to better handle 'i' & 'j'
        for c in xrange( numCol):  # from right to left
            if cc[r, c] != backgroundColor:
                edgeColumnInfo[r, 0] = 1 #indicate there is an edge pixel on this row
                edgeColumnInfo[r, 1] = c #indicate the column of the edge pixel                
                break
            
    return edgeColumnInfo

#def GetRightMostPixel (cc, backgroundColor = 0):
#    numRow = len(cc)
#    if numRow < 1:
#        return []
#    
#    numCol = len(cc[0])
#
#    edgeList = [];
#    
#    for r in xrange(numRow): # from botthom to better handle 'i' & 'j'
#        for c in xrange( numCol-1, 0, -1):  # from right to left
#            if cc[r, c] != backgroundColor:
#                edgeList.append([c, r])
#                break
#    return edgeList
#        
#def GetLeftMostPixel (cc, backgroundColor = 0):
#    numRow = len(cc)
#    if numRow < 1:
#        return []
#    
#    numCol = len(cc[0])
#    
#    edgeList = [];
#    
#    for r in xrange(numRow): # from botthom to better handle 'i' & 'j'
#        for c in xrange( numCol):  # from right to left
#            if cc[r, c] != backgroundColor:
#                edgeList.append([c, r])
#                break
#    return edgeList                
    
#=========================================================
if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print "Usage: CalcMinCCGapInImage <image_file>"
        sys.exit(-1)
         
    print CalcMinCCGapInImage(sys.argv[1])