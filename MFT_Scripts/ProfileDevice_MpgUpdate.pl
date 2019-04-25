#!/usr/bin/perl

#-----------------------------------------------------------------------
# MPG Update has two phases:
#  - Acquisition
#  - Processing (Parsing): it takes about 1~1.5 sec to process 1 MPG block
#                          Marketplace Common: ~ 1 sec
#                          Maketplace Content Retailer Spec: ~ 3sec
#                          Service Def: ~ 3 sec
#                          CPU throttling for SI ~40% per Mangesh
#    + Uncompress: gunzip
#    + PER decoding (binary XML to ASCII XML) by 3rd party lib:
#                 most CPU consuming ~700ms
#    + Parsing: ASCII XML to internal binary format
#
#
# QXDM messages related to MPG Update
# - Acquisition
#  + start: SiMgr: Looking to acquire 1 near team MPG block
#  +      : DEBUG OFMgr: Num of bytes:30 recvd on flow id:3
#  +      : INFO SiMgr: Not looking to acquire MpgBlkMsg
#  +      : INFO SiMsg: successfully added fragment (id: 0, 1/1) to MpgBlkMsg (ST: 1179273600, ver 2)
#  +  end : SiMgr: No more Near Term MPG blocks to
#
# - Parsing
#  + start: SiMgr: started parsing MpgBlkMsg
#  +      : SiMgr: finished parsing MpgBlkMsg # for one MPG block
#  +      : SiMgr: started parsing MpgBlkMsg
#  +      : SiMgr: finished parsing MpgBlkMsg # for another MPG block#
#  ...
#  + end :  SiMgr: No more postponed MPG blocks
#-----------------------------------------------------------------------
#
# Alternative:
#  APEX's perl script: ProcessDirectory_APEX5.pl processes dlf or isf file
# (located at C:\Program Files\APEX 5.x\Script) to generate
#  Debug_Messages_vs__Time.txt and CPU_Task_Usage_vs__Time.txt
#
# Grep the following from Debug_Messages_vs__Time.txt
#  grep -E 'Looking to acquire|No more|started parsing|finished parsing|\
#          recvd on flow id:3|Not looking to|added fragment' Debug_Messages_vs__Time.txt > t.txt
#
# Find the CPU from CPU_Task_Usage_vs__Time.txt
# The main tasks that are responsible for mpg updates are UI and FS Compat task.
#

