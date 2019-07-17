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
	if isdir(i+'/tables'):
		samp = i.split('/')[-1]
		for s in segs:
			f = glob(i+'/tables/*'+s+'*coverage.txt')
			if len(f) == 1:
				f = f[0]
				with open(f,'r') as c:
					for line in c:
						if "Reference" not in line:
							dbc.execute('insert into coverage values (?,?,?,?,?,?,?,?,?,?,?)', tuple([modTime, runID, numReads, samp, s])+tuple(line.split()))
			else:
				dbc.execute('insert into coverage values (?,?,?,?,?,?,?,?,?,?,?)', tuple([modTime, runID, numReads, samp, s,'','0','0','0','0','0']))
db.commit()
db.close()
