#!/usr/bin/python
# 
# This program 
#
# By Qiang Gao.
#=============================================================================== 

import sys
from pylab import *
import re

def ConvertNodeUniqueIdForRe (uid):
    # ".0.1" should be converted to "\\.0\\.1" for re.search
    e = uid.split('.')
    
    r = ''
    for ii in xrange( len(e) ):
        if e[ii] != '':
            r += ('\\.' + e[ii])
    return r
    
class KMeanTreePartition:
    # Constant
    maxNumNodes = 10
    barColors = ['#00ff00', '#008000', '#0000ff', '#ffff00', '#808000', '#000000', '#ff0000', '#a0a0a0', 'c', 'm']
    def __init__ (self, fileName, rootNodeUniqueId):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
        else:
            r = 'Node\\s+' + ConvertNodeUniqueIdForRe(rootNodeUniqueId) + '(\\.\\d)?[\\s*]'        
            
            self.chars = [] # characters covered by this root node
            charsIdx = {}
            self.charsNumSampleInChild = []
            for line in f:
                sect = line.rstrip().split(':')  # os.linesep could be used in strip
                if len(sect) < 3:
                    continue

                m = re.search(r, sect[0])
                if not m:
                    continue

#                    L3 Node .0.1.0*(  8): D B 0 9 n g 6 b : 9447 106 28 6 2 2 1 1                
                if m.group(1): # child node
                    c = sect[1].split(' ')
                    n = sect[2].split(' ')
                    a = zeros( len(self.chars) )
                    for ii in xrange( len(c) ):
                        if c[ii] != '':
                            a[ charsIdx[c[ii]] ] = int(n[ii])
                    self.charsNumSampleInChild.append(a)
                else:   # root node
                    e = sect[1].split(' ')
                    idx = 0
                    for ii in xrange( len(e) ):
                        if e[ii] != '':
                            self.chars.append( e[ii] )
                            charsIdx[e[ii]] = idx
                            idx += 1            
                print line.rstrip()
                
#            print self.chars
#            print charsIdx
#            print self.charsNumSampleInChild[0]
    def Plot(self):
        close()
        figure(figsize=(max (10, 40.0*len(self.chars)/80.0), 9), dpi=80)
        hold(True)
        
        ind = arange(len(self.chars))
#        legendLine = []
#        legendLabel = ['Node 0']    
#        legendLine.append(    
#                          bar(ind, self.charsNumSampleInChild[0], color=KMeanTreePartition.barColors[0],
#                              label = 'Node 0')[0]
#                          )
        bar(ind, self.charsNumSampleInChild[0], color=KMeanTreePartition.barColors[0],
          label = 'Node 0')[0]        
        btm = self.charsNumSampleInChild[0]               
        # the remaining candidates plotted as stacked bar
        # See http://matplotlib.sourceforge.net/examples/pylab_examples/bar_stacked.html
        #  and http://stackoverflow.com/questions/3211079/interactive-stacked-bar-chart-using-matplotlib-python
        for nn in xrange(1, len(self.charsNumSampleInChild)):
            if nn >= KMeanTreePartition.maxNumNodes:
                print "Number of nodes is >", KMeanTreePartition.maxNumNodes
                sys.exit(-1)

#            legendLabel.append('Node ' + str(nn))
#            legendLine.append(                    
#                              bar(ind, self.charsNumSampleInChild[nn], color=KMeanTreePartition.barColors[nn], bottom = btm,
#                                  label = 'Node ' + str(nn))[0]
#                              )
            bar(ind, self.charsNumSampleInChild[nn], color=KMeanTreePartition.barColors[nn], bottom = btm,
                                  label = 'Node ' + str(nn))                        
            btm = btm + self.charsNumSampleInChild[nn]
         
        #legend( legendLine, legendLabel, 'upper right')
        #see http://matplotlib.sourceforge.net/users/legend_guide.html
        #legend(legendLine, legendLabel, bbox_to_anchor=(1.05, 1), loc=2, mode="expand", borderaxespad=0.)         
        #legend(bbox_to_anchor=(1.05, 1, 0.3, .7), loc=2, borderaxespad=0.)
        legend(bbox_to_anchor=(0., 1.02, 1., .402), loc=3, ncol=5, mode="expand", borderaxespad=0.)
        xlabel('Char')
        ylabel('Num of samples')
        xticks(ind + 0.5, self.chars)
        show()
#============================================================
if __name__ == "__main__":    
    if len(sys.argv) < 3:
        print "USAGE: VisualizeKMeanTreePartition <KMeanTreeDefFile> <root_node_unique_ID>"
        print "  Example root node unique ID:"
        print "     \".\"  : the level 0 root node "
        print "     \".2\" : the level 1 root node with ID 2"
        sys.exit(-1)
    
    kmtp = KMeanTreePartition(sys.argv[1], sys.argv[2])
    kmtp.Plot()
        
