#!/usr/bin/python

from glob import glob
from os import getcwd
from os.path import isdir
from sys import argv, exit
import sqlite3 as sq3
from subprocess import check_output, CalledProcessError

usage = "\n\tUSAGE: "+argv[0]+" <numReads> <referenceModule> </path/to/blastDB> <fastaQuery> <seg> <test>\n"
if len(argv) < 3:
	print usage
	print "\n\t'test' prints sqlite3 cmd to stdout instead of calling\n\n"
	exit()

try:
	numReads = argv[1]
except IndexError:
	print usage
	exit()
root = '/'.join(argv[0].split('/')[:-2])
blastn = root+'/lib/ncbi-blast-2.7.1+/bin/blastn'
#blastDBroot = root+'/lib/ncbi-blast-2.7.1+/BlastDB/'
MIAdb = root+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()

runID = argv[2]

#segs = "HA MP NA NP NS PA PB1 PB2".split()

s = argv[5] #segs:
#fastas = glob(getcwd()+'/'+s+'/v'+argv[2]+'/*fasta')
fasta = argv[4] #fastas:
samp = ''.join(fasta.split('/')[-1].split('.')[0:-1]) #.replace('_','/')
#blastDB = blastDBroot+s+'/v-1_1/'+s
blastDB = argv[3]
try:
	blastResults = check_output([blastn, '-db', blastDB, '-query', fasta, '-num_threads', '8', '-perc_identity' , '99', '-outfmt', '6'])
except Exception as E:
	print E
for line in blastResults.split('\n'):
	line = line.split('\t')
	if len(line) == 12:
		if 'test' in argv:
			print 'insert into blast values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', tuple([runID, numReads, samp, s])+tuple(line)
		else:
			dbc.execute('insert into blast values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', tuple([runID, numReads, samp, s])+tuple(line))
db.commit()
db.close()
