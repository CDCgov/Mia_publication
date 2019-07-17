#!/usr/bin/python

from sys import argv, exit
from glob import glob
import sqlite3 as sq3

if len(argv) != 6:
	exit("\nUSAGE: "+argv[0]+" <alignedProteinFastaFile> <antigenicSitesFile> <RunID> <NumReads> <sampleID>\n")

fasta = argv[1]
antiFile = argv[2]
RunID = argv[3]
NumReads = argv[4]
SampleID = argv[5]

root = '/'.join(argv[0].split('/')[:-2])
MIAdb = root+'/db/MIA.db'

cvvs = glob(root+'/lib/Variants/cvv_*Fasta/*fasta')
cvvs = [x.split('/')[-1].strip('_AA.fasta').replace('_','/') for x in cvvs]

db = sq3.connect(MIAdb)
dbc = db.cursor()

antiDic = {}
with open(antiFile, 'r') as f:
	for line in f:
		l = line.strip().split('\t')
		antiDic[l[0]] = l[1]
def antiDicF(position, antiDic=antiDic):
	try:
		return antiDic[str(position)]
	except KeyError:
		return ''

fastaDic = {}
with open(fasta, 'r') as f:
	for line in f:
		if line[0] == '>':
			seqname = line.strip()[1:]
			fastaDic[seqname] = ''
		else:
			fastaDic[seqname] += line.strip()

for k in fastaDic.keys():
	if '/' in k:
		ref = k
	else:
		samp = k

if 'H3' in antiFile:
	startP = 16
elif 'H1' in antiFile:
	startP = 15

position = 0
for i in zip(fastaDic[ref], fastaDic[samp])[startP:]:
	if i[0] != '-':
		position += 1
	if i[0] != i[1]:
		match = '0'
	else:
		match = '1'
	dbc.execute('insert into cvv_vars values (?, ?, ?, ?, ?, ?, ?, ?, ?)', tuple([RunID, NumReads, SampleID, ref, str(position), i[0], i[1], match, antiDicF(position)]))
	#print [RunID, NumReads, SampleID, ref, str(position), i[0], i[1], match, antiDicF(position)]
db.commit()
db.close()
