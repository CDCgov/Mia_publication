#!/usr/bin/python

from sys import argv, exit
from os import getcwd
import sqlite3 as sq3
from re import findall
from glob import glob

usage = '''
	USAGE: python'''+argv[0]+''' <RunID> <NumReads>

	Run from IRMA directory of MIA output to load hana table
	with HxNx subtype data.

'''

if len(argv) != 3 or getcwd().split('/')[-1] != 'IRMA':
	exit(usage)

runID = argv[1]
numReads = argv[2]

MIAdb = '/'.join(argv[0].split('/')[:-2])+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()

toLoad = []
data = glob('barcode*/*_[HN]A*fasta')
for d in data:
	strain = findall(r'barcode\d*(?=/)',d)[0]
	subtype = findall(r'(?<=_)[HN]\d(?=\.fasta)',d)[0]
	if 'H' in subtype:
		seg = 'HA'
	elif 'N' in subtype:
		seg = 'NA'
	toLoad.append((runID, numReads, strain, seg, subtype))

#print toLoad
dbc.executemany("insert into hana values (?, ?, ?, ?, ?)", toLoad)
db.commit()
db.close()
