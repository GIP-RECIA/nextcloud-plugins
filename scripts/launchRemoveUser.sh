
date
rlog=$HOME/logs-esco
fdata=$HOME/data
rcode=$HOME/scripts


/bin/gzip $rlog/removeOldUser/*.log 

echo "Suppression définitive des comptes obsolètes: "
/usr/bin/nice $rcode/removeOldUser.pl -n 2000 -l 41 2>&1

date
