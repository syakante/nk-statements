from unicodedata import normalize
import pandas as pd
from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords
import multiprocessing as mp
from time import time
import re

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

raw = excel_to_df("../../sampleset-w-text.xlsx")
k = Kiwi()
punct = '"#$%&\'()*+,-/:;<=>@[\\]^_`{|}~《》'
raw['text_raw'] = raw['text_raw'].apply(lambda s: s.translate({ord(char): None for char in punct}))
ret_df = pd.DataFrame()
ret_df['sentence'] = raw.apply(lambda row: process_row(row), axis = 1).explode()
ret_df[['id', 'headline', 'link', 'Date', 'category']] = raw[['id', 'headline', 'link', 'Date', 'category']]

ret_df.to_excel("sentencesplit.xlsx")