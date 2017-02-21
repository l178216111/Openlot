#!/usr/bin/perl
use CGI;
use JSON;
use Spreadsheet::ParseExcel;
print "Content-type: application/json\n\n";
my $vatable="\/probeeng\/webadmin\/cgi\-bin\/OpenLot\/VA_table";
my $pathdir="\/probeeng\/webadmin\/cgi\-bin\/OpenLot\/";
##########################################################
my $cgi = new CGI;
my %unit;
$unit{attachement}=$cgi->param('fileName');
$unit{filename}=$unit{attachement};
$unit{filename}=~s/^.*(\\|\/)//;
$unit{filepath}=$pathdir.$unit{filename};
##########################################################
sub trim{
my $string=shift;
$string=~ s/\n*|\r*|^\s*|\s*$//g;
$string=~ s/\s{2}/\s/g;
$string=uc($string);
return $string;
}
sub upload{
        my $string_ref=shift;
        my %string=%$string_ref;
        my $file=$string{attachement};
        my $filepath=$string{filepath};
        my $filename=$string{filename};
        if ($file eq "\s"){
                return "$file no file get";
        }
        $filename=~ /.*\.(.*)/;
        if ($1 ne "xls" ){
                return "only support .xls format";
        }
        if (-f $filepath){
                return "$filename has exist";
                }
        open(OUTFILE,">$filepath")|| return "$filepath".$!;
        binmode(OUTFILE);
        while(my $bytesread=read($file,my $buffer,1024)){
                print OUTFILE $buffer;
                }
        close(OUTFILE);
        return '1';
        }
sub convert2VA {
	my $file_path=shift;
	my $VA_table=$vatable;
	my $parser = Spreadsheet::ParseExcel->new() or die $!;
	my $workbook = $parser->Parse("$file_path") or die $!;
	open(VA,">","$VA_table") or die $!;
	for my $worksheet ( $workbook->worksheets() ) {
        	print VA "VA {\n";
        	my ( $row_min, $row_max ) = $worksheet->row_range();
        	my ( $col_min, $col_max ) = $worksheet->col_range();
        	for my $row ( $row_min .. $row_max ) {
                	next if ($row==0);
                	my $key = $worksheet->get_cell( $row, '0' )->value();
                	my $value=$worksheet->get_cell( $row, '1' )->value();
                	next unless $key;
#               print VA "$key:$value\n";
                	print VA "$key:$value\n" if $key=~ /^D.*/;
        	}
        print VA "}";
        last;
}
	return "Update done";
}
my %output;
$output{success} = 'true';
$output{msg}=&upload(\%unit);
if ($output{msg} == 1){
	$output{msg}=&convert2VA($unit{filepath});	
	`rm $unit{filepath}`;
}
my $json=to_json(\%output);
print "$json";
