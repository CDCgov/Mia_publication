#!/usr/bin/python

from glob import glob
from os import getcwd
from os.path import isdir
from sys import argv, exit
import sqlite3 as sq3
from subprocess import check_output, CalledProcessError

usage = "\n\tUSAGE: "+argv[0]+" <numReads>\n"
if len(argv) < 2:
	print usage
	exit()

try:
	numReads = argv[1]
except IndexError:
	print usage
	exit()

root = '/'.join(argv[0].split('/')[:-2])
blastn = root+'/lib/ncbi-blast-2.7.1+/bin/blastn'
blastDBroot = root+'/lib/ncbi-blast-2.7.1+/BlastDB/'
MIAdb = root+'/db/MIA.db'
db = sq3.connect(MIAdb)
dbc = db.cursor()

runID = getcwd().split('/')[-2]

segs = "HA MP NA NP NS PA PB1 PB2".split()

samples = glob(getcwd()+'/*')
for i in samples:
	if isdir(i):
		samp = i.split('/')[-1]
		for s in segs:
			fasta = glob(i+'/*'+s+'*.fasta')
			if len(fasta) == 1:
				fasta = fasta[0]
				blastDB = blastDBroot+s+'/v-1_1/'+s
				try:
					blastResults = check_output([blastn, '-db', blastDB, '-query', fasta, '-num_threads', '8', '-perc_identity' , '80', '-outfmt', '6'])
					#print blastResults
				except Exception as E:
					print E
				for line in blastResults.split('\n'):
					line = line.split('\t')
					if len(line) == 12:
						#print 'insert into blast values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', tuple([runID, numReads, samp, s])+tuple(line)
						dbc.execute('insert into blast values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', tuple([runID, numReads, samp, s])+tuple(line))
db.commit()
db.close()
