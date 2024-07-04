
date
rlog=$HOME/logs-esco
fdata=$HOME/data
rcode=$HOME/scripts


/bin/gzip $rlog/removeOldUser/*.log 

echo "\nsuppression définitive des comptes obsolètes"
/usr/bin/nice $rcode/removeOldUser.pl -n 2000 -l 4 2>&1

date
