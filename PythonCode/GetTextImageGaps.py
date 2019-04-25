#!/usr/bin/python

import Image

def GetTextImageGaps (txtImgFile):
    i = Image.open(txtImgFile)
    pf = i.getprojection()

    print pf[0]
    print pf[1]

    return GetHolesInSequence(pf[0])

def GetHolesInSequence (seq, holeValue = 0):
    # A hole = consecutive elements that are equal to holeValue
    gaps = []

    state = -1;
    for ii in xrange( len(seq) ):
        if state == -1:
            if seq[ii] != holeValue:
                state = 0
        elif state == 0:
            if seq[ii] == holeValue:
                state = 1
        elif state >= 1:
            if seq[ii] == holeValue:
                state += 1
            else:
                gaps.append(state)
                state = 0
    return gaps

#==========================================
if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print 'USAGE: GetTextImageGaps.py <text_image>'
        sys.exit(-1)

    g= GetTextImageGaps(sys.argv[1])

    print 'Gap width: ' + str(g)

