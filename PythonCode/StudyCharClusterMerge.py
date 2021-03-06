#!/usr/bin/env python
import sys, os, string, math, random

# calculate Char 
def Char2Index(char):
    a = ord(char)
    if a >= ord('0') and a <= ord('9'):
        return a - ord('0');

    if a >= ord('A') and a <= ord('Z'):
        return 10 + a - ord('A');
    
    if a >= ord('a') and a <= ord('z'):
        return 36 + a - ord('a');        
    
    return -1

def Index2Char(idx):
    if idx >= 0 and idx <= 9:
        return chr(idx + ord('0'))

    if idx >= 10 and idx <= 35:
        return chr(idx - 10 + ord('A'))

    if idx >= 36 and idx <= 61:
        return chr(idx - 36 + ord('a'))
                           
    return ' '

def EuclideanDistance(x, y):
    assert len(x) == len(y)
    s = 0
    
    for i in xrange(len(x)):
        d = x[i] - y[i]
        s += (d * d)
        
    return math.sqrt(s)
    
class CharSimilarity:
    def __init__ (self, fileName):
        try:
            if fileName == '-':
                f = sys.stdin
            else:
                f = open(fileName, 'r')
        except IOError:
            print 'cannot open ', fileName
        else:
            charFeatures = []
            for line in f:
                sect = line.rstrip().split(',')  # os.linesep could be used in strip
                if len(sect) < 2:
                    continue    
                charIdx = Char2Index(sect[0])
                if charIdx < 0:
                    continue
                
                #TODO: remove assumption that chars in the files are ordered as 0-9, A-Z, a-z
                #TODO: remove ',' at the end of the line (generated by MATLAB)
                charFeatures.append(sect[1: len(sect) - 1])
            
#            print charFeatures    
            # convert to numbers
            self.numChar = len(charFeatures)
            for l_0 in xrange(self.numChar):
                for l_1 in xrange(len(charFeatures[l_0])):
                    charFeatures[l_0][l_1] = int(charFeatures[l_0][l_1])
                
            # similarity matrix in hash/dict as required by the runcubic function
            self.m = {}
            for n in xrange(self.numChar):
               self.m[n] = {}               
            for n in xrange(self.numChar):
               self.m[n][n] = 1.0  # already in similarity not distance!!
               
            max = 0.0
            for n in xrange(self.numChar):
                for i in xrange(n + 1, self.numChar):
                    d = EuclideanDistance( charFeatures[n], charFeatures[i]);                   
                    self.m[n][i] = d
                    self.m[i][n] = d
                    if d > max:
                        max = d
            
            # convert distance to similarity between 0 and 1 (inclusive)
            for n in xrange(self.numChar):
                for i in xrange(n + 1, self.numChar):                  
                    self.m[n][i] = 1 - self.m[n][i] / max 
                    self.m[i][n] = self.m[n][i]
            
            f.close()
    
# cubic complete link
def runcubic(hashobj, sim):
    #NOTE: assume similarity <=1 & >= 0
#    mergelist = ''
    mergelist = [];
    assign = {}
    eliminated = {}
    for n in range(hashobj):
       assign[n] = n
       eliminated[n] = 0
    for k in range(hashobj - 1):
        max = -1
        cl1 = -1
        cl2 = -1
        for n in range(hashobj):
           if eliminated[n]:
              continue
           for i in range(n):
              if eliminated[i]:
                 continue
              if sim[n][i] > max:
                 max = sim[n][i]
                 cl1 = i
                 cl2 = n
        assert cl1 >= 0 and cl2 >= 0
        eliminated[cl1] = 1
#        mergelist += `cl1`+':'+`cl2`+' '
        mergelist.append([cl1, cl2])
        
        for n in range(hashobj):
           if assign[n] == cl1:
              assign[n] = cl2
        # update the similarity matrix
        # the row corresponding to cl2
        #   is updated with similarity of cl1
        #   if similarity of cl1 is smaller
        for n in range(hashobj):
           if eliminated[n]:
              continue
           if sim[cl1][n] < sim[cl2][n]:
              smallersim = sim[cl1][n]
              sim[cl2][n] = smallersim
              sim[n][cl2] = smallersim
    return mergelist

def computesourcedata(hashobj, mode):
   assert mode == 'random' or mode == 'pathological'
   
   random.seed(2012)
   
   sourcedata = {}
   for n in range(hashobj):
      sourcedata[n] = {}
   for n in range(hashobj):
      sourcedata[n][n] = 1.0
   max = 0
   for n in range(hashobj):
      for i in range(n + 1, hashobj):
         if mode == 'random':
            sim = random.random()
         else:
            sim = n / (1.0 * hashobj) + i / (1.0 * hashobj * hashobj)
         if sim > max:
            max = sim
         sourcedata[n][i] = sim
         sourcedata[i][n] = sim
   assert max <= 1
   return sourcedata
def simtosim(hashobj, oldmatrix):
   newmatrix = {}
   for n in range(hashobj):
      newmatrix[n] = {}
      for i in range(hashobj):
         newmatrix[n][i] = oldmatrix[n][i]
   return newmatrix
#=============================================================
if __name__ == '__main__':
    assert len(sys.argv) >= 2
    
    #print Char2Index(sys.argv[1]), Index2Char(Char2Index(sys.argv[1])) 
    
    #hashobj = 20
    #
    #sourcedata = computesourcedata(hashobj, 'random')
    #simmatrix = simtosim(hashobj,sourcedata)
    #mergerscubic = runcubic(hashobj,simmatrix)
    #print 'cubic',mergerscubic
    
    sm = CharSimilarity(sys.argv[1])
#    print Index2Char(18), Index2Char(47)
#    print Index2Char(0), Index2Char(50)
#    print Index2Char(24), Index2Char(50)
#    print Index2Char(30), Index2Char(56)
#    print Index2Char(35), Index2Char(61)
#    print sm.m[0]
    mergerscubic = runcubic(sm.numChar, sm.m)
    #print 'cubic',mergerscubic
    for ii in xrange( len(mergerscubic) ):
        print mergerscubic[ii][0],mergerscubic[ii][1]

