#!/usr/bin/python

import sys
import argparse

#######################
#Ujwal Bagal: March 2018
#######################


def translateDNA(sequence):
	codontable = {
	    'ATA':'I', 'ATC':'I', 'ATT':'I', 'ATG':'M',
	    'ACA':'T', 'ACC':'T', 'ACG':'T', 'ACT':'T',
	    'AAC':'N', 'AAT':'N', 'AAA':'K', 'AAG':'K',
	    'AGC':'S', 'AGT':'S', 'AGA':'R', 'AGG':'R',
	    'CTA':'L', 'CTC':'L', 'CTG':'L', 'CTT':'L',
	    'CCA':'P', 'CCC':'P', 'CCG':'P', 'CCT':'P',
	    'CAC':'H', 'CAT':'H', 'CAA':'Q', 'CAG':'Q',
	    'CGA':'R', 'CGC':'R', 'CGG':'R', 'CGT':'R',
	    'GTA':'V', 'GTC':'V', 'GTG':'V', 'GTT':'V',
	    'GCA':'A', 'GCC':'A', 'GCG':'A', 'GCT':'A',
	    'GAC':'D', 'GAT':'D', 'GAA':'E', 'GAG':'E',
	    'GGA':'G', 'GGC':'G', 'GGG':'G', 'GGT':'G',
	    'TCA':'S', 'TCC':'S', 'TCG':'S', 'TCT':'S',
	    'TTC':'F', 'TTT':'F', 'TTA':'L', 'TTG':'L',
	    'TAC':'Y', 'TAT':'Y', 'TAA':'_', 'TAG':'_',
	    'TGC':'C', 'TGT':'C', 'TGA':'_', 'TGG':'W',
	    }
	protein_seq=''
	
	for i in range(0,len(sequence),3):
		if sequence[i:i+3] in codontable:
			protein_seq=protein_seq+codontable[sequence[i:i+3]]

		else:
			protein_seq=protein_seq+"X"	

	print protein_seq



if __name__=="__main__":


	parser=argparse.ArgumentParser(description='Translate DNA to amino acids')
	parser.add_argument("-i", dest="input",required=True, help='Provide dna sequence file', type=str)
	parser.add_argument('--version', action='version', version='%(prog)s 1.0')
	args=parser.parse_args()


	header=''
	seq=''

	for line in open(args.input,'r'):
		if line.startswith(">"):
			header=line.strip()
			print header
		else:
			seq+=line.strip().upper()
			translateDNA(seq)
		seq=''	
		
