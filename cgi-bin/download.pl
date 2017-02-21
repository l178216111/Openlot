#!/usr/local/bin/perl

require "/exec/apps/bin/lib/perl5/JN/download.pm";
use CGI;

my $html= new CGI;
my $filename =  $html->param('filename');
my $path = '/probeeng/webadmin/cgi-bin/OpenLot/downloads';
my $file = "$path/$filename";
sendFileToBrowser($html,$file);



=pod
my $filepath='./OpenLotSummary_1433404036.xls';

use CGI;
my $html= new CGI;
#get the file name from URL ex. http://<server_IP>/cgi-bin/download.cgi?a=testing.txt
my $file= $html->param(''); 
# $file is nothing but testing.txt
#my $filepath= "/var/www/upload/$file";

print ("Content-Type:application/x-download\n");
print "Content-Disposition: attachment; filename=OpenLotSummary_1433404036.xls\n\n";

open FILE, "< $filepath" or die "can't open : $!";
binmode FILE;
local $/ = \10240;
while (<FILE>){
    print $_;
}

    close FILE;
=cut
