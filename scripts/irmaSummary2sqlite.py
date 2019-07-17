#!/usr/bin/python

from glob import glob
from os import chdir, getcwd, listdir
from os.path import isdir, getmtime
from sys import argv, exit
import datetime as dt
import time
import sqlite3 as sq3


usage = "\n\tUSAGE: "+argv[0]+" <numReads>\n"
if len(argv) < 2:
	print usage
	exit()

try:
	numReads = argv[1]
except IndexError:
	print usage
	exit()

MIAdb = '/'.join(argv[0].split('/')[:-2])+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()

#now = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
runID = getcwd().split('/')[-2]
modTime = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(getmtime(getcwd())))

segs = "HA MP NA NP NS PA PB1 PB2".split()

samples = glob(getcwd()+'/*')
for i in samples:
	match, nomatch, chim, ha, mp, na, np, ns, pa, pb1, pb2 = int(0),'0',int(0),'0','0','0','0','0','0','0','0' # match and chim intentionally numeric
	if isdir(i+'/logs'):
		samp = i.split('/')[-1]
		f = glob(i+'/logs/NR_COUNTS_log.txt')
		if len(f) == 1:
			f = f[0]
			with open(f,'r') as c:
				for line in c:
					line = line.strip()
					if '.match' in line:
						match += int(line.split(':')[-1]) # must sum all match lines
					elif '.nomatch' in line:
						nomatch = line.split(':')[-1] # last nomatch is correct
					elif '.chim' in line:
						chim += int(line.split(':')[-1]) # sum all chim 
					elif 'ASSEMBLY' in line and 'HA' in line:
						ha = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'MP' in line:
						mp = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'NA' in line:
						na = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'NP' in line:
						np = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'NS' in line:
						ns = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'PA' in line:
						pa = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'PB1' in line:
						pb1 = line.split(':')[-1]
					elif 'ASSEMBLY' in line and 'PB2' in line:
						pb2 = line.split(':')[-1]
			# LOAD DATABASE
			match, chim = str(match), str(chim)
			dbc.execute('insert into irma_summary values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', tuple([modTime, runID, numReads, samp, match, nomatch, chim, ha, mp, na, np, ns, pa, pb1, pb2]))
db.commit()
db.close()
