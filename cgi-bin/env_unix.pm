
$ENV{ORACLE_HOME} = "/u01/app/oracle/product/client_11.2" if not defined $ENV{ORACLE_HOME};
$ENV{PATH} = "$ENV{ORACLE_HOME}/bin:$ENV{PATH}";
$ENV{TNS_ADMIN} = '/exec/apps/tools/oracle';

use lib '/usr/local/apache2/cgi-bin/lib';

1;
