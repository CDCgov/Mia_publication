#!/usr/bin/python

from sys import argv, exit
import sqlite3 as sq3

if len(argv) != 5:
	print "\n\tUSAGE: python "+argv[0].split('/')[-1]+" <RunID> <DirNum> <sequencing_summary.txt> <barcoding_summary.txt>\n"
	exit()

data = {}
with open(argv[3], 'r') as d:	
	d.readline() # skip header
	for line in d:
		l =line.strip().split('\t')
		data[l[1]] = [argv[1], argv[2], l[1], l[7], l[11], l[12]]
		#dbc.execute('insert into albacore_summary values (?,?,?,?,?,?,?,?)',(argv[1], argv[2], l[1], l[7], l[11], l[12], 'Null', 'Null'))
with open(argv[4], 'r') as d:
	d.readline() # skip header
	for line in d:
		l = line.strip().split('\t')
		data[l[0]].extend([l[1], l[5]])
		#dbc.execute('update albacore_summary set Barcode=?, BarcodeScore=? where RunID=? and Dir=? and ReadID=?', (l[1], l[5], argv[1], argv[2], l[0]))



MIAdb = '/'.join(argv[0].split('/')[:-2])+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()
dbc.execute('BEGIN TRANSACTION')
for v in data.values():
	dbc.execute('insert into albacore_summary values (?,?,?,?,?,?,?,?)', tuple(v))
dbc.execute('COMMIT') # Adding this statment decreases run time from ~0.4s to ~0.05s but throws error?

db.commit()
db.close()
