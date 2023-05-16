from collections import Counter
from unicodedata import normalize
import csv
import numpy as np

# from konlpy.tag import Hannanum
# from konlpy.utils import concordance, pprint
from matplotlib import pyplot
from mecab import MeCab

with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
    stopwords = f.read().split("\n")

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

def my_tokenizer(s:str): #->List[str]
	#normalize
	doc = normalize("NFKC", s)
	tbl = str.maketrans(punct, ' '*len(punct))
	doc = doc.translate(tbl)
	m = MeCab()

df = []

with open('checkset.csv', encoding = 'utf-8') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=",")
    next(csvreader) #skip header
    i = 0
    for row in csvreader:
	    	df.append([i] + list(map(lambda x: normalize("NFKC", x), row)))
	    	i += 1
	    	#though we're really only interested in normalizing the text columns... whatever
#df = np.array(df) #aiiieeeeeeeeeee
#0: id | 1: headline | 2: link | 3: text | 4: date | 5: year | 6: category
m = MeCab()
sw_df = []
sh_df = []
bd_df = []
jp_df = []
my_pointer = {"SWORD": sw_df, "SHIELD": sh_df, "BADGE": bd_df, "JAPANFOCUS": jp_df}

for i in range(len(df)):
	which_cat = df[i][6] #--> "SWORD", "SHIELD", "BADGE", "JAPANFOCUS", or "IFFY" idk ignore that one... thres only two
	#print(which_cat)
	if(which_cat in my_pointer.keys()):
		print("ok")
		my_pointer[which_cat].append([df[i][x] for x in [0, 3, 6]]) #potentially datetime is of interest but not rn
