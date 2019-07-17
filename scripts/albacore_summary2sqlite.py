#!/usr/bin/python

from sys import argv, exit
import sqlite3 as sq3

if len(argv) != 4:
	print "\n\tUSAGE: python "+argv[0].split('/')[-1]+" <RunID> <DirNum> <sequencing_summary.txt>\n"
	exit()

MIAdb = '/'.join(argv[0].split('/')[:-2])+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()
dbc.execute('BEGIN TRANSACTION')
with open(argv[3], 'r') as d:	
	for line in d:
		if 'filename' not in line:
			l =line.split('\t')
			dbc.execute('insert into albacore_summary values (?,?,?,?,?,?,?,?)',(argv[1], argv[2], l[1], l[7], l[12], l[13], l[19], l[20]))
dbc.execute('COMMIT') # Adding this statment decreases run time from ~0.4s to ~0.05s but throws error?

'''
# UPDATE PROGRESS TABLE with correct number of FAST5 files (inotifywait operation may have missed some counts)
try:
	progressCount = dbc.execute('select max(Reads) from progress where RunID = ? and DirType = "FAST5"', [argv[1]]).fetchone()[0]
	summaryCount = dbc.execute('select count(*) from albacore_summary where RunID = ?', [argv[1]]).fetchone()[0]
except sq3.InterfaceError:
	progressCount, summaryCount = 0,0
if summaryCount > progressCount:
	dbc.execute("update progress set Reads = ? where RunID = ? and DirType = 'FAST5'", (summaryCount, argv[1]))
'''
db.commit()
db.close()
