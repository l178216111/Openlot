
use lib '/usr/local/apache2/cgi-bin/lib';
$ENV{ORACLE_HOME} = "/u01/data/product/8.1.6" if not defined $ENV{ORACLE_HOME};
$ENV{PATH} = "$ENV{ORACLE_HOME}/bin:$ENV{PATH}";
$ENV{TNS_ADMIN} = '/exec/apps/tools/oracle';
our $this_dir="/usr/local/apache2/cgi-bin/holdreports_linux";
our $bin_dir="/usr/local/apache2/cgi-bin/holdreports_linux";
our $web_bin="http://zch01app04v.ap.freescale.net/cgi-bin/holdreports_linux/";
1;
