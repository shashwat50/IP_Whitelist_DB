from netaddr import IPSet
import sys

ips = IPSet()

i = open('input_ips.txt','r')

for line in i:
  line=line.rstrip('\n')
  ips.add(line)
for j in ips:
  print(j)

i.close()