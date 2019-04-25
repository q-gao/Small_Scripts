#!/usr/bin/python
import sys

if len(sys.argv) < 2 :
	print ("Usage: hbtp_capture.py <data_file_location_on_device>")
	exit(-1)
	
# subprocess tutorial: http://sharats.me/the-ever-useful-and-neat-subprocess-module.html#a-simple-usage
import subprocess

#=============================================================================================
# Get single char from keyboard
#  See http://code.activestate.com/recipes/134892/  
#	   http://stackoverflow.com/questions/510357/python-read-a-single-character-from-the-user
#  a curses based solution? : http://stackoverflow.com/questions/10693256/how-to-accept-keypress-in-command-line-python
class _Getch:
    """Gets a single character from standard input.  Does not echo to the
screen."""
    def __init__(self):
        try:
            self.impl = _GetchWindows()
        except ImportError:
            self.impl = _GetchUnix()

    def __call__(self): return self.impl()

class _GetchUnix:
    def __init__(self):
        import tty, sys

    def __call__(self):
        import sys, tty, termios
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        return ch


class _GetchWindows:
    def __init__(self):
        import msvcrt

    def __call__(self):
        import msvcrt
        return msvcrt.getch()

cmdProcess = subprocess.Popen(['cmd.exe'], stderr = subprocess.PIPE, stdin = subprocess.PIPE, stdout = subprocess.PIPE)		

#=============================================================================================
# # code to monitor cmdProcess.stdout
# # the following will monitor the stdout forever
# for line in cmdProcess.stdout:
# 		print line

# from threading import Thread
# from Queue import Queue, Empty		

# io_q = Queue()
# def stream_watcher(identifier, stream):
    # for line in stream:
        # io_q.put((identifier, line))

    # if not stream.closed:
        # stream.close()
		
# # threads to monitor the stdout and stderr
# Thread(target=stream_watcher, name='stdout-watcher',
        # args=('STDOUT', cmdProcess.stdout)).start()
# Thread(target=stream_watcher, name='stderr-watcher',
        # args=('STDERR', cmdProcess.stderr)).start()
		
# def printCmdProcessOutput():
    # while True:
        # try:
            # # Block for 1 second.
            # item = io_q.get(True, 1)
        # except Empty:
            # # No output in either streams for a second. Are we done?
            # if cmdProcess.poll() is not None:  # None means cmdProcess "not terminated" yet
                # break
        # else:
            # identifier, line = item
            # print identifier + ':', line

# # thread to print out stdout
# Thread(target=printCmdProcessOutput, name='printCmdProcessOutput').start()		

#=================================================================================
# execute commands
import time

cmd = 'adb shell\n'
print (cmd)
cmdProcess.stdin.write(cmd)
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed

cmd = 'hbtp_tool\n'
print (cmd)
cmdProcess.stdin.write(cmd)
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed

cmd = 'dump ' + sys.argv[1] + '\n'
print (cmd)
cmdProcess.stdin.write(cmd)
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed

cmd = 'startRecord\n'
print (cmd)
cmdProcess.stdin.write(cmd)
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed
# key = raw_input('Enter a string followed by ENTER: ')  
# print "Entered string is " + key
getch = _Getch()
print ("Press any key to exit...")
getch()

cmd = 'stopRecord\n'
print (cmd)
cmdProcess.stdin.write(cmd)
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed

cmdProcess.stdin.write('exit\n')
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed
cmdProcess.stdin.write('exit\n')
time.sleep(.1)	# needed to give enough time for the command in the stream to be executed

import os
cmd =  'adb pull ' + sys.argv[1]
print (cmd)
os.system(cmd)

cmd =  'adb shell rm ' + sys.argv[1]
print ('\n' + cmd)
os.system(cmd)

cmdProcess.terminate()

