#!/usr/local/bin/perl
use lib "/exec/apps/bin/lib/perl5";
use env_unix;
use Data::Dumper;
use lib_cgi;
use lib_dbconn;
use POSIX;
use Time::Local;
use JSON;
use CGI;
use CGI qw(:standard);
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
use CONFAnalysis;

require "/exec/apps/bin/lib/perl5/Mask.pm";

print "Content-type: application/json\n\n";

my $bindir="/probeeng/webadmin/cgi-bin/OpenLot/";
$promis_tbl_owner = 'bat3ptorrent';
my $str=CONFAnalysis->new();
$str->LoadCONF($bindir."VA_table") or die $!;
my %MappingState;

my $currentTime = time();

$MappingState{wait} = 'D,S,T';
$MappingState{hold} = 'E,G,H,K,L,O,P,U,V,X,Y,a,c';
$MappingState{running} = 'J,i';

$MappingState{D} = 'Wait';
$MappingState{S} = 'Wait';
$MappingState{T} = 'Wait';
$MappingState{E} = 'Hold';
$MappingState{G} = 'Hold';
$MappingState{H} = 'Hold';
$MappingState{K} = 'Hold';
$MappingState{L} = 'Hold';
$MappingState{O} = 'Hold';
$MappingState{P} = 'Hold';
$MappingState{U} = 'Hold';
$MappingState{V} = 'Hold';
$MappingState{X} = 'Hold';
$MappingState{Y} = 'Hold';
$MappingState{J} = 'Running';
$MappingState{i} = 'Running';


my $conditions = {};
$conditions->{platform} = uc param('plat');
$conditions->{mask} = uc param('mask');
$conditions->{device} = uc param('device');
$conditions->{stage} = uc param('stage');
$conditions->{holdcode} = uc param('holdcode');
$conditions->{status} = param('status');
$conditions->{lottype} = uc param('lottype');
$conditions->{session} = lc param('session');
$conditions->{lotid} = lc param('lotid');
$toExcel = param('toExcel');

#debug
#$conditions->{mask} = 'M41P';
#$conditions->{platform} = 'CATALYST';
#end

my $dbh_torr=DBI->connect(&getconn('tjn','promis'));

my $CategoryMap = {};
my $sql_getCategory = "select a.partprcdname,a.partprcdversion,a.category from $promis_tbl_owner.catg a where a.catgnumber = 31";
my $sth_getCatefory = $dbh_torr->prepare($sql_getCategory);
$sth_getCatefory->execute();
$sth_getCatefory->bind_columns(
	undef,\$partname,\$partversion, \$category
);
while ( $sth_getCatefory->fetch() ) {
	$CategoryMap->{$partname}->{$partversion}->{platform} = $category;
}
$sth_getCatefory->finish();
#######################################################################################
my @Storage;
my ($lotid,$device,$dpartname,$priority,$stage,$curmainqty,$lottype,$state,$pdpw);
######################################################################################
#wafer cage info
#####################################################################################
my $sql_getWaferCage = 
"select a.lotid ,a.partname,d.parmval,a.priority,a.stage,a.curmainqty,a.lottype,a.state,d.matconvrate from $promis_tbl_owner.actl a
left join 
(select b.prcdname,c.parmval,e.matconvrate  from $promis_tbl_owner.prcd b 
left join $promis_tbl_owner.PPARNTOTALPARMS c
on b.prcdname = c.prcdname and b.prcdversion = c.prcdversion  
left join $promis_tbl_owner.pauxmattypeconvcount e
on b.prcdname = e.prcdname and b.prcdversion = e.prcdversion  
where b.activeflag = 'A' and c.parmname ='\$DIESHIPPART') d
on a.partname = d.prcdname
where a.prodarea='BAT3' AND state not in ('B','p') and stage in ('910W-DN','910W-PSWR','9100-PSWR')";
my $sth_getWaferCage = $dbh_torr->prepare($sql_getWaferCage);
$sth_getWaferCage->execute();
$sth_getWaferCage->bind_columns( undef,\$lotid,\$device,\$dpartname,\$priority,\$stage,\$curmainqty,\$lottype,\$state,\$pdpw);
while ( $sth_getWaferCage->fetch() ) {
	my $unit={};
        $unit->{lotid} = $lotid;
        $unit->{priority}=$priority;
        $unit->{device} = $device;
        $unit->{dpartname} = $dpartname;
        $unit->{stage} = $stage;
	$unit->{status} = $MappingState{$state};
        $unit->{pdpw} = $pdpw;
        $unit->{qty} = $curmainqty;
	if ($dpartname ne '') {
		my $VA=$str->block('VA')->key($dpartname);
        	if ($VA eq '') {
                	$unit->{va}='-';
        	}else{
                	$unit->{va}=$VA;
        	}
	} else {
		$unit->{va}='-';
	}
        if ( $unit->{va} == 0 ) {
                $unit->{'1va'} =0;
        }else{
                $unit->{'1va'} =  sprintf("%.2f",1/$unit->{va});
        }
        $unit->{vxp}=sprintf("%.2f",$unit->{qty} *  $unit->{va} * $unit->{pdpw});
        $unit->{lottype} = $lottype;
	$unit->{platform} = $CategoryMap->{$unit->{device}}->{$partversion}->{platform};
        my $flag1 = 1; # 0 stands for invalid , default valid
        foreach my $condition(keys %$conditions) {
                if($conditions->{$condition} ne '') {
                        my @array = split(',|\s',uc($conditions->{$condition}));
                        my $flag2 = 0; # 0 stands for invalid
                        foreach my $ele(@array) {
                                if (uc($unit->{$condition}) eq $ele ) {
                                        $flag2 = 1; # set to valid
                                }
                        }
                        if($flag2 == 0) {
                                $flag1 = 0;
                        }
                }
        }
        if($flag1 == 1) {
                push @Storage, $unit;
        }
}
$sth_getWaferCage->finish();
my %output;
if ($toExcel == 1) {
	my $xls_file = "OpenLotWafercageSummary_$currentTime.xls";
        if (-f $xls_file && -w _) {
        	my $rs = unlink($xls_file);
                #print "remove $rs file(s)\n";
        } elsif ( -f $xls_file && ! -w _) {
                die "$xls_file is unreadable, please contact JiangNan check permission!\n";
        }
        my $path = "/probeeng/webadmin/cgi-bin/OpenLot/downloads";
        my $sheet_name = 'Wafer_Cage Summary';
        my $xls_obj = new Spreadsheet::WriteExcel("$path/$xls_file");
        my $red_style = $xls_obj->add_format(bg_color  => 'red');
        my $yellow_style = $xls_obj->add_format(bg_color  => 'yellow');
#       my $green_style = $xls_obj->add_format(bg_color  => 'green');
        my $green_style = $xls_obj->add_format(bg_color  => 0x0B);
        my $sheet = $xls_obj->add_worksheet( $sheet_name );
        my $datestamp = strftime('%F %T',localtime($currentTime));

        # Lot Summary Result
        $sheet->write(0,0,"Wafer_Cage Summary Results on $datestamp");
        my @title = ('Platform','Device','DiePartname','lotID','Qty','PDPW','VA','1/VA','VPQ','Priority','Lottype','Stage','Status');
        my @content = ('platform','device','dpartname','lotid','qty','pdpw','va','1va','vxp','priority','lottype','stage','status');
        for(my $i=0;$i<@title;$i++) {
                $sheet->write(2,$i,$title[$i]);
        }
        @Storage = sort { $b->{va} <=> $a->{va} } @Storage;
        for(my $i=0;$i<@Storage;$i++) {
                my $unit = $Storage[$i];
                for(my $j=0;$j<@content;$j++) {
                        if($content[$j] eq 'status') {
                                if($unit->{$content[$j]} eq 'Wait') {
                                        $sheet->write(3+$i,$j,$unit->{$content[$j]},$yellow_style);
                                } elsif($unit->{$content[$j]} eq 'Hold') {
                                        $sheet->write(3+$i,$j,$unit->{$content[$j]},$red_style);
                                } elsif($unit->{$content[$j]} eq 'Running') {
                                        $sheet->write(3+$i,$j,$unit->{$content[$j]},$green_style);
                                } else {
                                        $sheet->write(3+$i,$j,$unit->{$content[$j]});
                                }
                        } else {
                                $sheet->write(3+$i,$j,$unit->{$content[$j]});
                        }
                }
        }

        my %output;
        $output{success} = 'true';

        $output{file} = "$xls_file";
        my $json = to_json(\%output);
        $xls_obj->close();
        print "$json";
        exit;
}

$output{success} = 'true';
$output{results} = \@Storage;
my $json = to_json(\%output);
print $json;
