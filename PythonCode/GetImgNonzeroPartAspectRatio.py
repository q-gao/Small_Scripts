#!/usr/bin/python
import sys
import Image

def GetImgNonzeroPartAspectRatio(imgName):
    # See class method in http://code.activestate.com/recipes/52304-static-methods-aka-class-methods-in-python/
    # RETURN:
    #   -1 : if no char in the image
    
    i = Image.open(imgName)
    bbox = i.getbbox()
      
    if len(bbox) < 4:
        return -1
    
    return float((bbox[2] - bbox[0])) / float((bbox[3] - bbox[1]))

if __name__ == "__main__":
    if len(sys.argv) < 2:  # like C
        print "USAGE: GetImgNonzeroPartAspectRatio <img_file>"
        sys.exit(-1)    
        
    print "Non-zero part aspect ratio = %f" % GetImgNonzeroPartAspectRatio( sys.argv[1] )