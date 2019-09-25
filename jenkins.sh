#!/bin/bash

>Final_IP_CIDR.txt
>temp_IP.txt
>ips_to_add.txt

#----------------Get all whitelisted cidrs in cidr.txt file--------------------#

echo "-----------Downloading whitelisted CIDR----------------"
echo ""
mysql -u infosec -h 3.223.76.241 -p$password whitelisted -e 'select * from expanded_ips;' 2>/dev/null > all_data.txt
cat all_data.txt | awk '{print $2}' | grep -v ip | sort -n | uniq > cidr.txt
echo ""
echo "-----------Downloaded whitelisted CIDRs----------------"
echo ""

#---------Check if IP is already whitelisted----------#

echo "-----------Checking if IPs are already whitelisted------------"
echo ""
python3 comp.py
cat Final_IP_CIDR.txt | cut -d '[' -f2 | cut -d ']' -f1 | tr ',' '\n' | cut -d "'" -f2 > ips_to_add.txt

if [ `cat ips_to_add.txt | grep -i '.' | wc -l` -ge '1' ]
then
cat ips_to_add.txt >> cidr.txt

#-----------------Get site list from incapsula-----------------#

python3 /home/ssingh/incapsula/incapsula-cli/root/src/incap.py site list | grep -v "Getting site list" | awk '{print $2 ":" $NF}' > sites.txt

#--------------Delete and Re-add-----------------#

echo ""
echo "-------------Whitelisting IPs in Incapsula--------------"
echo ""
for incap_id in `cat sites.txt`
do
echo $incap_id
site_id=`echo $incap_id | cut -d ':' -f2`
site_name=`echo $incap_id | cut -d ':' -f1`
ids=`python3 /home/ssingh/incapsula/incapsula-cli/root/src/incap.py site status $site_id | grep -i "ip exception" | awk '{for(i=12;i<=NF;++i)print $5}' | sort -n | uniq`
for i in `echo $ids`
do
echo "IPs Deleted"
#python3 /home/ssingh/incapsula/incapsula-cli/root/src/incap.py site whitelist --whitelist_id=$i --delete_whitelist=true blacklisted_ips $site_id
done
echo "IPs Re-added"
#python3 /home/ssingh/incapsula/incapsula-cli/root/src/incap.py site whitelist --ips=`cat cidr.txt | tr '\n' ','` blacklisted_ips $site_id
echo ""
done
echo "-------------IPs Whitelisted for all Sites--------------"
echo ""

echo "--------------Adding whitelisted IPs to DB----------------"
echo ""

>temp_IP.txt
#unset ip
for j in `cat sites.txt`
do
site_name=`echo $j | cut -d ':' -f1`
site_id=`echo $j | cut -d ':' -f2`
id=`python3 /home/ssingh/incapsula/incapsula-cli/root/src/incap.py site status $site_id | grep -i "ip exception" | awk '{for(i=12;i<=NF;++i)print $5}' | sort -n | uniq`
mysql -u infosec -h 3.223.76.241 -p$password whitelisted 2>/dev/null << EOF
update expanded_ips set whitelist_id = '${id}' where site_name = '${site_name}';
EOF
for i in `cat ips_to_add.txt`
do
echo $i,$id,$site_name,$site_id >> temp_IP.txt
#[ ! -z "$ip" ] && ip=$ip,\(\'$i\',\'$id\',\'$site_name\',\'$site_id\'\)
#[ -z "$ip" ] && ip=\(\'$i\',\'$id\',\'$site_name\',\'$site_id\'\)
done
done
cat temp_IP.txt | ssh ec2-user@3.223.76.241 "sudo tee /var/lib/mysql/temp_ip.txt"
mysql -u infosec -h 3.223.76.241 -p$password whitelisted 2>/dev/null << EOF
LOAD DATA INFILE '~/temp_ip.txt' into table expanded_ips FIELDS TERMINATED BY ',' (ip, whitelist_id, site_name, site_id);
EOF
echo ""
echo "-------------IPs added to DB successfully--------------"
else
echo "No IPs to whitelist...."
fi