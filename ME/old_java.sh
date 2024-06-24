ALL_JAVA=$(for i in $(find /u01 -name java -type f -exec ls {} \;  2>/dev/null); do echo $($i -version 2>&1 | grep version):$i;  done | sort -k3)
echo "$ALL_JAVA"
OLD_JAVA=$(echo "$ALL_JAVA"| head -n 1)
echo Oldest :"$OLD_JAVA"
JAVA_DIFF=$(echo "$ALL_JAVA" | sort -u | awk "NR==1{print}END{print}" | cut -c 21-23 | awk '{$X = $1-prev1 ;prev1=$1;print ;}' | tail -n 1)
echo em_result="$JAVA_DIFF|$OLD_JAVA"