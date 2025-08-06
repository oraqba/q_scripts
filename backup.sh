#!/bin/bash

# Author JSZ 
# Script: backup.sh <ORACLE_SID> <Level=0|1>
# Purpose: Simple script to perform Oracle database incremental level <Level=0|1> backup with control file and SPFILE
# Use crontab entry like: 
#0 20 * * * /bin/bash /path/to/backup.sh orcl 0 >> /u01/app/oracle/backup/cron_backup.log 2>&1

# Environment variables
export ORACLE_SID=$1 
export LEVEL=$2
export ORACLE_HOME=/u01/app/oracle/product/19.27/db_home1
export BACKUP_DIR=/u01/app/oracle/backup/$ORACLE_SID  
export LOG_DIR=/u01/app/oracle/backup/$ORACLE_SID/logs
export DATE=$(date +%Y%m%d_%H%M%S)
export LOGFILE=$LOG_DIR/backup_L${LEVEL}_$DATE.log

# Create directories if they don't exist
mkdir -p $BACKUP_DIR
mkdir -p $LOG_DIR

# RMAN backup script
$ORACLE_HOME/bin/rman target / << EOF > $LOGFILE
RUN {
configure RETENTION POLICY TO recovery window of 7 days;
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;
BACKUP INCREMENTAL LEVEL ${LEVEL} DATABASE  FORMAT '$BACKUP_DIR/incr_L${LEVEL}_${DATE}_%U';
BACKUP CURRENT CONTROLFILE FORMAT '$BACKUP_DIR/ctlbkp_${DATE}_%U.ctl';
BACKUP ARCHIVELOG ALL FORMAT '$BACKUP_DIR/arch_${DATE}_%U';
BACKUP SPFILE FORMAT '$BACKUP_DIR/spfile_${DATE}_%U.ora';
sql "ALTER DATABASE BACKUP CONTROLFILE TO TRACE AS ''$BACKUP_DIR/ctltrc_${DATE}.trc''";
CROSSCHECK BACKUP;
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT OBSOLETE;
}
EXIT;
EOF

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "Incremental Level $LEVEL backup with control file and SPFILE completed successfully at $DATE"
    echo "Log file:$LOGFILE"
else
    echo "Backup failed! Check log file: $LOGFILE"
    exit 1
fi
exit 0
