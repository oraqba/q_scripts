for DBNAME in $(srvctl config database)
do
srvctl config database -d $DBNAME -a | awk -v dbuniqname="$DBNAME" \
'BEGIN { FS=":" }
$1~/Database name/ || $1~/DBNAME/ {dbname = "-db" $2}
$1~/Oracle home/ || $1~/ORACLE_HOME/ {dbhome = "-oraclehome" $2}
$1~/Spfile/ || $1~/SPFILE/ {spfile = "-spfile" $2}
$1~/Password file/ || $1~/PWFILE/ {pwfile = "-pwfile" $2}
$1~/Domain/ || $1~/DOMAIN/ {domain = "-domain" $2}
$1~/Start options/ || $1~/STARTOPT/ {startopt = "-startoption" $2}
$1~/Database role/ || $1~/DBROLE/ {dbrole = "-role" $2}
END { if (avail == "-a ") {avail = ""}; printf "%s %s %s %s %s %s %s %s %s\n", "srvctl add database -db ", dbuniqname, dbname, dbhome, spfile, pwfile, domain, startopt, dbrole }';
done

for DBNAME in $(srvctl config database)
do
srvctl config service -d $DBNAME -a | awk -v dbuniqname="$DBNAME" \
'BEGIN { FS=":" }
$1~/Service name/ || $1~/SERVICENAME/ {servicename = "-service" $2}
$1~/Service role/ || $1~/SERVICEROLEROLE/ {servicerole = "-role" $2}
END { if (avail == "-a ") {avail = ""}; printf "%s %s %s %s\n", "srvctl add service -db ", dbuniqname, servicename, servicerole }';
done

for DBNAME in $(srvctl config database)
do
srvctl config database -d $DBNAME -a | awk -v dbuniqname="$DBNAME" \
'BEGIN { FS=":" }
$1~/Database name/ || $1~/DBNAME/ {dbname = "-db" $2}
$1~/Oracle home/ || $1~/ORACLE_HOME/ {dbhome = "-oraclehome" $2}
$1~/Spfile/ || $1~/SPFILE/ {spfile = "-spfile" $2}
$1~/Password file/ || $1~/PWFILE/ {pwfile = "-pwfile" $2}
$1~/Domain/ || $1~/DOMAIN/ {domain = "-domain" $2}
$1~/Start options/ || $1~/STARTOPT/ {startopt = "-startoption" $2}
$1~/Database role/ || $1~/DBROLE/ {dbrole = "-role" $2}
END { if (avail == "-a ") {avail = ""}; printf "%s %s %s %s %s %s %s %s %s\n", "srvctl add database -db ", dbuniqname, dbname, dbhome, spfile, pwfile, domain, startopt, dbrole }';
srvctl config service -d $DBNAME -a | awk -v dbuniqname="$DBNAME" \
'BEGIN { FS=":" }
$1~/Service name/ || $1~/SERVICENAME/ {servicename = "-service" $2}
$1~/Service role/ || $1~/SERVICEROLEROLE/ {servicerole = "-role" $2}
END { if (avail == "-a ") {avail = ""}; printf "%s %s %s %s\n", "srvctl add service -db ", dbuniqname, servicename, servicerole }';
done

