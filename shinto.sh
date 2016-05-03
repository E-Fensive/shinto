#!/bin/sh

# Shinto v.1
# J. Oquendo

if [ "$(id -u)" != "0" ]; then
   clear ; printf "Shinto needs to be run as root or using sudo\n" 1>&2
   exit 1
fi

now=`date +'%H%M%S-%m%d%Y'`
mkdir /tmp/shinto-$now
syscinfo=sysctla-info-$now.txt
cd /tmp/shinto-$now
clear

echo "Creating report in /tmp/shinto-$now"
sleep 3

echo "<br><br><center><table width=90%><tr><td><font face=courier><pre>" > report.txt

printf "\n\nGathering date and time"
printf "<hr><h3><center>Current System Information</h3></center>" >> report.txt

	date >> report.txt
	uname -a >> report.txt
	id >> report.txt
	uptime >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n<hr>\n" >> report.txt
printf "<h3><center>sysctl information output separately</h3></center>" >> report.txt
printf "\n<a href=$syscinfo>sysctl -a output</a>" >> report.txt

	sysctl -a >> $syscinfo

printf "\n<hr>\n" >> report.txt
printf "\n\nGathering disk information"
printf "<h3><center>Currently mounted disks</h3></center>" >> report.txt

	camcontrol devlist|sed 's:<::g;s:>::g' >> report.txt
	printf "\n<center><h3><b>GPART Information</h3></b></center>" >> report.txt
	gpart show >> report.txt

printf "\n<hr>\n" >> report.txt
printf "<h3><center>Current networking configuration</h3></center>" >> report.txt
printf "\n\nNoting current ethernet configuration and ARP information"

	ifconfig >> report.txt

printf "\n\n<b><h3><center>ARP information</center></b></h3>\n" >> report.txt

	arp -an >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\nNoting current environment variables"
printf "<h3><center>Current environment variables</h3></center>" >> report.txt

	printenv >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\nNoting who is currently logged into the system"
printf "<h3><center>Current users on the system</h3></center>" >> report.txt

	who >> report.txt
	printf "\n\n" >> report.txt ; w >> report.txt
	printf "\n\nNoting last login information for each user"
	printf "<h3><center>Last login data for all users</h3></center>" >> report.txt
	mkdir users
	awk -F ":" '!/nologin/ && !/#/{print $1}' /etc/passwd |\
	while read user ; do lastlogin $user >> report.txt
	done >/dev/null 2>&1

printf "\n\nNoting current identity"
printf "<h3><center>Currently logged in as</h3></center>" >> report.txt

	whoami >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\nNoting opened, established and closed connections"
printf "<h3><center>Current opened, established and connections</h3></center>" >> report.txt

	sockstat -4 >> report.txt
	mkdir connections
	printf "\n<h3><center>Connection information (excluding RFC 1918 IP space)</h3></center>" >> report.txt
	sockstat -4 | awk '/:/ && !/\*/{print $7}' | sed 's#:# #g'|\
	awk '{print $1}' | grep -vi "^127\.\|^192\.168\.\|^10\.\|^172\.1[6-9]\.\|^172\.2[0-9]\.\|^172\.3[0-1]\.\|^::1$" |\
	sort -u |\
	while read con
		do

			printf "\n\n" >> report.txt
			echo "whois -h asn.shadowserver.org 'peer $con'" | sh >> connections/$con.txt
			printf "\n\n" >> connections/$con.txt
			whois -h whois.arin.net $con >> connections/$con.txt
			traceroute -m 16 -w 3 $con >> connections/$con.txt >/dev/null 2>&1 &
			printf "<a href=connections/$con.txt target=_blank>$con.txt</a>" >> report.txt
			printf "\n" >> report.txt
			echo "whois -h asn.shadowserver.org 'peer $con'" | sh >> report.txt
		done

printf "\n<hr>\n" >> report.txt
printf "\n\nGathering information on running processes"
printf "<h3><center>Currently running processes via ps</h3></center>" >> report.txt

	ps -aux >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\n<h3><center>Gathering information on <b>unique</b> processes running via lsof</h3></center>" >> report.txt

	lsof | awk '{printf ("%-15s %-12s %-22s \n", $1,$2,$3)}' |sort -u >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\n<h3><center>Listing open files associated with unique PIDs</h3></center>" >> report.txt

	lsof |\
	awk '{printf ("%-15s %-12s %-22s \n", $1,$2,$3)}' |\
	sort -u | awk '{print $2}' | grep [0-9] |\
	while read pid ; do lsof -p $pid|perl -p -e 's:COMMAND:\n\nCOMMAND:g' ; done >> report.txt 

printf "\n\nGetting checksums for opened files"
printf "\n<center><h3>MD5 Checksums for opened files</center></h3>\n" >> report.txt

	lsof | perl -MDigest::MD5=md5_hex -ane '
            $f = $F[ $#F ];
            -f $f and printf qq|%s %s\n|, $f, md5_hex( $f )
        ' | awk '{printf ("%-75s %-12s \n", $1,$2)}' | sort -u >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\nNoting loaded modules"
printf "<h3><center>Modules detected by kernel</h3></center>" >> report.txt

	kldstat -v >> report.txt
	printf "\n\n<center><h3>Module checksums</center></h3>\n" >> report.txt
	kldstat -v | sed 's:(::g;s:)::g'|\
	perl -MDigest::MD5=md5_hex -ane '
            $f = $F[ $#F ];
            -f $f and printf qq|%s %s\n|, $f, md5_hex( $f )
        
	'|\
	awk '{printf ("%-45s %-12s \n", $1,$2)}' | sort -u >> report.txt 

printf "\n<hr>\n" >> report.txt
printf "\n\nListing all services that started from rc.d"
printf "<h3><center>Services in /etc/rc.d and /usr/local/etc/rc.d</h3></center>" >> report.txt

	service -r >> report.txt

printf "\n<hr>\n" >> report.txt
printf "\n\nListing all last logins"
printf "<h3><center>Last logins information</h3></center>" >> report.txt

	for i in `ls /var/log/utx.*` ; do last -f $i >> report.txt ; done

	perl -pi -e 's:TCP:<font color=#990000><b>TCP</font></b>:;s:UDP:<font color=#990000><b>UDP</font></b>:g' report.txt
	perl -pi -e 's:wtmp begins:\n\nwtmp begins:g' report.txt

printf "\n\nSleeping for two minutes to allow ensure traceroute finishes\n\n" ; sleep 120


mv report.txt report.html
find . | xargs zip shinto-report.zip 

echo ""
echo -n "Do you want to email this report? [yes or no]: "
read yno
case $yno in

        [yY] | [yY][Ee][Ss] )

echo -n "Enter your e-mail address"
echo ""
read email
                uuencode shinto-report.zip shinto-report.zip | mail -s "Shinto report" $email 
                ;;

        [nN] | [n|N][O|o] )
                echo "exiting";
                exit 1
                ;;
        *) echo ""
            ;;
esac


echo -n "Do you want to view in Firefox? [yes or no]: "
read yno
case $yno in

        [yY] | [yY][Ee][Ss] )

                firefox report.html
                ;;

        [nN] | [n|N][O|o] )
                printf "\n\nShinto has finished\n";
                exit 1
                ;;
        *) echo ""
            ;;
esac


printf "\n\n"
