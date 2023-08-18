from unicodedata import normalize
import pandas as pd
from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords
import multiprocessing as mp
from time import time
import re
import argparse

def excel_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_excel(filename, dtype='unicode', header=pd_header)
	return df

def process_row(row):
	#otherColVals = row[['id', 'headline', 'link', 'Date', 'category']]
	sentenceList = [s.text for s in k.split_into_sents(row['text_raw'])]
	return(sentenceList)

if __name__ == "__main__":
	# parser = argparse.ArgumentParser(description = "Split articles by sentence in an excel file.")
	# parser.add_argument("--input", "-i", type=str, required = True, help="Input file.")
	# parser.add_argument("--output", "-o", type=str, required = True, help="Output file.")
	# parser.add_argument("--text", "-t", type=int, required = True, help="Column number containing string docs you wish to tokenize.")
	# args = parser.parse_args()
	#? I think split_sentences.R is the actual file
	
	raw = excel_to_df("../../sampleset-w-text.xlsx")
	k = Kiwi()
	punct = '"#$%&\'()*+,-/:;<=>@[\\]^_`{|}~《》'
	raw['text_raw'] = raw['text_raw'].apply(lambda s: s.translate({ord(char): None for char in punct}))
	ret_df = pd.DataFrame()
	ret_df['sentence'] = raw.apply(lambda row: process_row(row), axis = 1).explode()
	ret_df[['id', 'headline', 'link', 'Date', 'category']] = raw[['id', 'headline', 'link', 'Date', 'category']]

	ret_df.to_excel("sentencesplit.xlsx")