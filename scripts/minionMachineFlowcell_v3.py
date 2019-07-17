#!/usr/bin/python3

# Works with multiread fast5

from sys import argv, exit, stderr
from time import sleep
import datetime as dt
import warnings
with warnings.catch_warnings(): # To suppress annoying FutureWarning from h5py import
	warnings.simplefilter('ignore')
	import h5py

if len(argv) < 2:
	exit('\n\tUSAGE: '+argv[0]+' <readfile.fast5>\n')

def loopUntilErrorFree(c=-1): 
	c+=1
	try:
		with h5py.File(argv[1], 'r') as f:
			global machine, flowcell, runID, flowcell_type, seq_kit, numReads
			machine = str(f[list(f.keys())[1]]['tracking_id'].attrs['device_id']).split("'")[1].upper()
			flowcell = str(f[list(f.keys())[1]]['tracking_id'].attrs['flow_cell_id']).split("'")[1].upper()
			runID = str(f[list(f.keys())[1]]['tracking_id'].attrs['run_id']).split("'")[1].upper()
			flowcell_type = 'FLO-MIN106'  #str(f[list(f.keys())[1]]['context_tags'].attrs['flowcell_type']).split("'")[1].upper()
			seq_kit = str(f[list(f.keys())[1]]['context_tags'].attrs['sequencing_kit']).split("'")[1].upper()
			numReads = str(len(list(f.keys())))
	except (OSError, NameError, KeyError) as E:
		if c % 100 == 0:
			stderr.write('\n'+dt.datetime.now().strftime("[%Y-%m-%d %H:%M:%S]")+'\t'+argv[1]+'\n'+str(E))
		sleep(5)
		loopUntilErrorFree(c)

loopUntilErrorFree()

if '-c' in argv:
	try:
		with open(argv[3]+'kitcell.py', 'a+') as o:
			print("#!/usr/bin/python", "seqKit = '"+seq_kit+"'", "flowcell = '"+flowcell+"'","runID = '"+runID+"'", "sep='\n'","file=o")
	except:
		exit('\n\tUSAGE: '+argv[0]+' <readfile.fast5>\n')
else:
	print(machine+'\t'+flowcell+'\t'+flowcell_type+'\t'+seq_kit+'\t'+numReads)
