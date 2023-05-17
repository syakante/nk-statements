from collections import Counter
from unicodedata import normalize
import csv
import numpy as np
import pandas as pd
from konlpy.tag import Okt
# from konlpy.utils import concordance, pprint

with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
    stopwords = set(f.read().split())

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

def csv_to_df(filename='../checkset.csv', skip_header=True):
	print("ok1")
	#df = []
	# with open(filename, encoding = 'utf-8') as csvfile:
	#     csvreader = csv.reader(csvfile, delimiter=",")
	#     if skip_header:
	#     	next(csvreader)
	#     i = 0
	#     for row in csvreader:
	# 	    	df.append([i] + list(map(lambda x: normalize("NFKC", x), row)))
	# 	    	i += 1
		    	#though we're really only interested in normalizing the text columns... whatever
	#df = np.array(df) #aiiieeeeeeeeeee
	#0: id | 1: headline | 2: link | 3: text | 4: date | 5: year | 6: category
	df = pd.read_csv(filename)
	return df
	sw_df = []
	sh_df = []
	bd_df = []
	jp_df = []
	my_pointer = {"SWORD": sw_df, "SHIELD": sh_df, "BADGE": bd_df, "JAPANFOCUS": jp_df}

	for i in range(len(df)):
		print(i)
		which_cat = df[i][6] #--> "SWORD", "SHIELD", "BADGE", "JAPANFOCUS", or "IFFY" idk ignore that one... thres only two
		#print(which_cat)
		if(which_cat in my_pointer.keys()):
			#print("ok")
			my_pointer[which_cat].append([df[i][x] for x in [0, 3, 6]]) #potentially datetime is of interest but not rn
	return np.array(df)

def my_tokenizer(doc:str): #->List[str]
	doc = normalize("NFKC", doc)
	tbl = str.maketrans(punct, ' '*len(punct))
	doc = doc.translate(tbl)
	o = Okt()
	o_morphs = o.morphs(doc)
	o_morphs2 = [word for word in o_morphs if word not in stopwords]
	del(o_morphs)
	#interesting where "은" could be a stopword or mean silver or sth but idk how to identify that. POS???
	#or just manually add some missed stopwords after a few trials

	#basically just need to watch out for "핵 에는 핵" (from "핵에는 핵으로")
	#because if we do the following V without accounting for this edge case we'll get some haek-somethingunintended token
	#therefore if we find haek and the previous token(s) (if possible) compose "핵 에는", then combine that whole token into one
	#since we're processing it left to right, it's more like if we encounter haek and the last haek token we just merged was "핵 에는"
	#otherwise if find standalone haek token, attach it to the next token
	#and all other tokens are just the morphs from Okt.
	#anyway once we finish tokenizing you can do other more interesting things (embeddings??????!!!!!)

	#also most/all of the articles start with (date and other header junk) so figure out how to ignore those
	clean_tokens = []

	i=0
	while i < len(o_morphs2):
	    token = o_morphs2[i]
	    if len(token) < 0:
	        #idt this would happen
	        print("h")
	        i += 1
	        continue
	    if(o_morphs2[i] == "핵"):
	        # if(i < len(o_morphs2)-1):
	        #     print("next token:", o_morphs2[i+1])
	        # else:
	        #     print("(no next token)")
	        # if(i > 0):
	        #     print("preceding token:", o_morphs2[i-1])
	        # else:
	        #     print("(no previous token)")
	        #^ though this won't happen because we attach to the following token anyway
	        if(i > 0 and clean_tokens[-1] == "핵에는"):
	            print("here")
	            clean_tokens[-1] = "핵에는 핵으로"
	            i += 1
	            continue
	        if(i < len(o_morphs2)-1):
	            token = o_morphs2[i] + o_morphs2[i+1]
	            i += 1
	        else:
	            print("somehow found haek by itself at the end of the document.")
	            print(clean_tokens[-1])
	    if(o_morphs2[i] == "론" and i < len(o_morphs2)-1 and o_morphs2[i+1][0] == "설"):
	        print("ok")
	        token = "론설"
	        o_morphs2[i+1] = o_morphs2[i+1][1:]
	        i += 1
	    clean_tokens.append(token)
	    i += 1

	clean_tokens = [word for word in clean_tokens if word not in stopwords]
	return clean_tokens

mydf = np.array(csv_to_df())
mydf[, 2] = np.apply_along_axis(my_tokenizer, )