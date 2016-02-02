#!/bin/bash
xprop -notype 32c _NET_WM_ICON |
  perl -0777 -pe '@_=/\d+/g;
	    printf "P7\nWIDTH %d\nHEIGHT %d\nDEPTH 4\nMAXVAL 255\nTUPLTYPE RGB_ALPHA\nENDHDR\n", splice@_,0,2;
			    $_=pack "N*", @_;
					    s/(.)(...)/$2$1/gs' > icon.pam
