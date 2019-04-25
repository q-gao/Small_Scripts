#!/usr/bin/perl
#
#   geturl11.pl-- Retrieve any URL using HTTP 1.1, and save to a local file
#
#   (C) 1997 James Marshall (james@jmarshall.com)
#
#   OVERALL OPERATION:
#       First, if a filename is given on the command line, open it for
#   writing and select() it.  This way, the rest of the program can simply
#   print with no filehandle, and the output will be correctly routed either
#   to STDOUT or to the local file.
#       After parsing the hostname, port number, and path from the URL,
#   the program opens a socket to the HTTP server with &newsocketto().
#   It sends a simple HTTP 1.1 GET request, including the "Host:" and
#   "Connection: close" headers, and waits for the socket response with
#   select().
#       To distinguish between an HTTP 0.9 response (which has no headers)
#   and a normal HTTP 1.x response, the program reads the first five bytes
#   of the response.  If they are not "HTTP/", then HTTP 0.9 is assumed,
#   and the entire socket output is copied to STDOUT (or the local file).
#   HTTP 0.9 is very rare.
#       If the response is HTTP 1.x, then the remainder of the status line
#   and headers are read.  If the status code is 100, that response is
#   discarded and another status line and headers are read, until the
#   response is no longer 100.  Then, if the status code is 301, 302, or 303,
#   the socket is closed and the program essentially restarts, aiming this
#   time for the URL given in the "Location:" response header.  This program
#   redirects a request no more than five times, to avoid a potential
#   infinite loop.
#       Otherwise, if the status code is anything other than 200 (success),
#   this program dies.
#       So now we have a 200 response for the URL we requested.  If the
#   response is in chunked format, decode it and write the resulting data
#   to the output.  Otherwise, if the "Content-Length:" response header is
#   present, copy only that many bytes from the socket to the output.
#   Otherwise, copy over all socket output.
#       The program then closes the socket and any output file, and exits.
#
#   DIFFERENCES BETWEEN THIS AND geturl10.pl (which uses HTTP 1.0):
#       1. The HTTP request has two extra headers and a different HTTP
#           version.
#       2. When reading the response, this program loops until a
#           non-100 status code is returned.
#       3. A chunked response is decoded correctly.
#
#   NOTE:
#       Some parsing in this program isn't perfect, but will almost always
#   work.  Specifically, in its quest to be an understandable demo, this
#   program doesn't strictly follow the BNF's for things like header field
#   contents and URL's.  If you plan to write commercial-quality software,
#   use more complete regular expressions.  See the BNF's in the HTTP spec,
#   RFC 822, and RFC 2396 (URL/URI syntax).
#
#   For platform-independence, this program uses \015\012 instead of \r\n
#   for the CRLF sequence.
#
#   To use this script with Perl 4:
#       1. Remove "use Socket" and see note in &newsocketto().
#       2. Add "$*= 1"; remove "m" flag from
#               location/content-length/transfer-encoding matches.
#

use Socket ;    # Perl 5 only

# Uncomment this for Perl 4
# $*= 1 ;

$/= "\012" ;    # default for Unix, but Macs need it set explicitly


# Read the URL and optional filename from the command line
(($URL,$fname)= @ARGV) || &usage ;
&usage if $URL=~ /^-/ ;

# Open and select the local file, if given on the command line
if ($fname) {
    open(SAVEFILE, ">$fname") || die "Couldn't open $fname for writing: $!" ;
    select(SAVEFILE) ;
}



# Basically, the whole program.
# Put this in a block, to restart on 300-level responses.
GETURL: {

    # Only support HTTP URLs; scheme defaults to HTTP
    $URL=~ m#^([\w+.-]+)://(.*)# && ( ($scheme,$URL)= ($1,$2) ) ;
    die "Sorry, $0 only supports HTTP URLs.\n" unless $scheme=~ /^(http)?$/i ;

    # parse the URL, simply (doesn't do much error-checking)
    ($host, $port, $path)= ($URL=~ m#([^/:]*):?([^/]*)(/.*)?$#i) ;
    $port= ($port || 80) ;
    $path= ($path || "/") ;


    # Open socket to host
    ($success, $errmsg)= &newsocketto(*S, $host, $port) ;
    die $errmsg unless $success ;

    # Send request, including User-Agent: header for Net politeness
    print S "GET $path HTTP/1.1\015\012",
            "Host: $host\015\012",
            "Connection: close\015\012",
            "User-Agent: GetURL11/1.0\015\012\015\012" ;

    # Wait for socket response with select()
    vec($rin= '', fileno(S), 1)= 1 ;
    select($rin, undef, undef, 60) || die "No response from $host:$port: $!" ;


    # Read first five chars, to determine if is HTTP 0.9
    $numread= 0 ;
    while ( ($numread<5)
            && ($thisread= read(S, $status_line, 5-$numread, $numread)) ) {
        $numread+= $thisread ;
    }
    defined($thisread) || die "Couldn't read response: $!" ;

    # handle the rare HTTP 0.9 response (which has no header data)
    if ($status_line!~ m#^HTTP/#) {
        print $status_line ;
        print while read(S, $_, 16384) ;

    # handle HTTP 1.x response
    } else {

        # Read header blocks until we get non-100 response
        do {
            # finish reading the status line
            # $/= "\012" ;
            $status_line.= <S> ;
            ($status_code)= ($status_line=~ m#^HTTP/\d+\.\d+\s+(\d+)#) ;

            # read $headers
            $headers= '' ;
            while (<S>) {
                last if /^\015?\012/ ;  # end on LF or CRLF
                $headers.= $_ ;
            }
            $headers=~ s/\015?\012[ \t]+/ /g ;     # unfold multi-line headers

            # Clear $status_line for next read
            $status_line= '' if ($status_code == 100) ;

        } until ($status_code != 100) ;


        # Redirect 301, 302, 303 responses, but avoid infinite redirection loop
        if ($status_code=~ /^(301|302|303)$/) {
            unless ( ($URL)= ($headers=~ /^location:[ \t]*(\S*)/im) ) {
                die "No Location: header in $status_code response; "
                  . "headers are:\n$status_line$headers\n\n" ;
            }
            ($numredirects++ > 5)
                && die "Redirected more than five times, quitting" ;
            print STDERR "Redirecting to $URL\n" ;
            close(S) ;
            redo GETURL ;
        }


        # If not 200 response, then die
        ($status_code == 200)
            || die "Got $status_code response; headers are:\n"
                 . "$status_line$headers\n\n" ;


        # If response is chunked, handle it.  Note that a chunked encoding
        #   takes precedence over a Content-Length: header.
        if ($headers=~ /^transfer-encoding:[ \t]*chunked\b/im) {

            # Read chunks and write to output
            # Note that hex() will automatically ignore a semicolon and beyond
            # $/= "\012" ;
            while ($chunk_size= hex(<S>) ) {
                $lefttoget= $chunk_size ;
                while ($lefttoget && ($thisread= read(S, $buf, $lefttoget)) ) {
                    print $buf ;
                    $lefttoget-= $thisread ;
                }
                defined($thisread)
                    || die "Couldn't read chunked response body: $!" ;
                $_= <S> ;   # clear CRLF after chunk
            }

            # Read footers (not needed in this app, but here for demonstration)
            while (<S>) {
                last if /^\015?\012/ ;  # end on LF or CRLF
                $headers.= $_ ;
            }
            $headers=~ s/\015?\012[ \t]+/ /g ;     # unfold multi-line headers

        # If there is Content-Length: header, only copy that many bytes
        #   to STDOUT.
        } elsif ( ($content_length)=
                        ($headers=~ /^content-length:[ \t]*(\d*)/im) ) {
            $lefttoget= $content_length ;
            while ($lefttoget
                    && ($thisread= read(S, $buf, &min($lefttoget,16384)) )) {
                print $buf ;
                $lefttoget-= $thisread ;
            }
            defined($thisread) || die "Couldn't read response body: $!" ;

            # Die if we didn't get all the bytes we were expecting
            $lefttoget
                && die "Not all data was read; expected $content_length, got "
                        . ($content_length-$lefttoget) . "." ;

        # No Content-Length: header, so copy entire socket output to STDOUT
        } else {
            print while read(S, $_, 16384) ;
        }

    }

    close(S) ;


} # GETURL


# Close the local file if needed
close(SAVEFILE) if $fname ;


exit ;


#--------- newsocketto, usage, min -----------------------------------


# Open a socket to a given host and port.
# Returns TRUE, with open socket in S, or returns (FALSE, $error_message).
# NOTE IF USING PERL 4: Remove "use Socket" from the beginning of the
#   script, and add the following line, setting your values as necessary:
#     $AF_INET= 2 ; $SOCK_STREAM= 1 ;  # Usually in /usr/include/sys/socket.h
#   Then, change AF_INET to $AF_INET and SOCK_STREAM to $SOCK_STREAM below.
sub newsocketto {
    local(*S, $host, $port)= @_ ;
    local($hostaddr, $remotehost) ;

    # Create the remote host data structure, from host name or IP address
    ($hostaddr= ($host=~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)
                  ?  pack('C4', $1, $2, $3, $4)     # for IP address
                  :  (gethostbyname($host))[4] )    # for alpha host name
        || return(0, "Couldn't find IP address for $host") ;

    $remotehost= pack('S n a4 x8', AF_INET, $port, $hostaddr) ;

    # Create the socket and connect to the remote host
    socket(S, AF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2])
        || return(0, "Couldn't create socket: $!") ;
    connect(S, $remotehost)
        || return(0, "Couldn't connect to $host:$port: $!") ;

    select((select(S), $|=1)[0]) ;      # unbuffer the socket
    return (1, "") ;      # success!
}


# Explain usage
sub usage {
    die <<EOF ;
To download an HTTP URL to stdout, or to a local file, use
    $0 URL [filename]
EOF
}


# Return the minimum of a list of values
sub min {
    local($min)= $_[0]+0 ;  # force to numeric
    foreach (@_) {
        $min= $_ if $_<$min ;
    }
    return $min ;
}

