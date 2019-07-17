#!/usr/bin/python

from sys import argv, exit
import sqlite3 as sq3

if len(argv) != 2:
	print "\n\tUSAGE: python "+argv[0].split('/')[-1]+" <RunID> \n"
	exit()

MIAdb = '/'.join(argv[0].split('/')[:-2])+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()

# UPDATE PROGRESS TABLE with correct number of FAST5 files (inotifywait operation may have missed some counts)
try:
	progressCount = dbc.execute('select max(Reads) from progress where RunID = ? and DirType = "FAST5"', [argv[1]]).fetchone()[0]
	summaryCount = dbc.execute('select count(*) from albacore_summary where RunID = ?', [argv[1]]).fetchone()[0]
except sq3.InterfaceError:
	progressCount, summaryCount = 0,0
if summaryCount > progressCount:
	dbc.execute("update progress set Reads = ? where RunID = ? and DirType = 'FAST5'", (summaryCount, argv[1]))

db.commit()
db.close()
