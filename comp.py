#!/usr/bin/env python

from netaddr import *

ipset=IPSet()
cidrset=IPSet()
finalipset=IPSet()

f = open("cidr.txt","r")
for line in f:
	line=line.rstrip('\n')
	cidrset.add(line)

p = open("input_ips.txt","r")
for line in p:
	line=line.rstrip('\n')
	ipset.add(line)

o = open("temp_IP.txt","a")

q = open("Final_IP_CIDR.txt","a")

print ("IP's to be whitelisted....")
for i in ipset:
	if (i in cidrset) == False:
		print (i)
		o.write(str(i))
		o.write("\n")

	if (i in cidrset) == True:
		print (str(i) + " is already whitelisted.Skipping....")

o.close()

o = open("temp_IP.txt","r")

for line in o:
        line=line.rstrip('\n')
        finalipset.add(line)
			
q.write(str(finalipset))

q.close()
o.close()
p.close()
f.close()
