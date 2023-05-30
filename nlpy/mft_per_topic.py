from collections import Counter
from unicodedata import normalize
import csv
#import numpy as np
import pandas as pd
import itertools
#from konlpy.tag import Okt
from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords
import multiprocessing as mp
from time import time

#o = Okt()
k = Kiwi()
k_sw = Stopwords()

# with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
#     stopwords = set(f.read().split())

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

def csv_to_df(filename='../checkset-fixed.csv', skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_csv(filename, dtype='unicode', header=pd_header, encoding='utf8')
	#idk why pandas is reading two rows as NA when they're right there. wtf.
	# --> I think it had to do with article length bricking the csv file.
	# with open(filename, encoding='utf-8') as csvfile:
	# 	myReader = csv.reader(csvfile)
	# 	if skip_header:
	# 		next(myReader)
	# 	df = list(myReader)
	# print("Read csv", filename)
	return df
	
	# sw_df = []
	# sh_df = []
	# bd_df = []
	# jp_df = []
	# my_pointer = {"SWORD": sw_df, "SHIELD": sh_df, "BADGE": bd_df, "JAPANFOCUS": jp_df}

	# for i in range(len(df)):
	# 	print(i)
	# 	which_cat = df[i][6] #--> "SWORD", "SHIELD", "BADGE", "JAPANFOCUS", or "IFFY" idk ignore that one... thres only two
	# 	#print(which_cat)
	# 	if(which_cat in my_pointer.keys()):
	# 		#print("ok")
	# 		my_pointer[which_cat].append([df[i][x] for x in [0, 3, 6]]) #potentially datetime is of interest but not rn
	# return np.array(df)

def kiwi_tokenizer(doc:str): #->List[str]
	try:
		print("normalizing encoding...")
		doc = normalize("NFKC", doc)
	except:
		print("error, probably missing txt due to bricked csv")
		return []
	print("removing punctuation...")
	tbl = str.maketrans(punct, ' '*len(punct))
	doc = doc.translate(tbl)
	print("tokenizing with Kiwi...")
	kiwi_tokens = k.tokenize(doc, stopwords=k_sw) #--> List of Token objects. We're interested in .form attribute
	kiwi_words = [t.form for t in kiwi_tokens]
	clean_tokens = []
	i=0
	print("adjusting for 핵 prefix...")
	while i < len(kiwi_words):
	    token = kiwi_words[i]
	    if len(token) < 0:
	        #idt this would happen
	        print("Something went wrong.")
	        i += 1
	        continue
	    if(kiwi_words[i] == "핵"):
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
	        if(i < len(kiwi_words)-1):
	        	print("attached 핵.")
	        	token = kiwi_words[i] + kiwi_words[i+1]
	        	i += 1
	        else:
	            print("somehow found 핵 by itself at the end of the document.")
	            print(clean_tokens[-1])
	    if(kiwi_words[i] == "론" and i < len(kiwi_words)-1 and kiwi_words[i+1][0] == "설"):
	        print("print for this other manual thing")
	        token = "론설"
	        kiwi_words[i+1] = kiwi_words[i+1][1:]
	        i += 1
	    clean_tokens.append(token)
	    i += 1

	#clean_tokens = [word for word in clean_tokens if word not in stopwords]
	print("Done tokenizing!")
	return clean_tokens


def my_tokenizer(doc:str): #->List[str]
	#print(type(doc))
	doc = normalize("NFKC", doc)
	tbl = str.maketrans(punct, ' '*len(punct))
	doc = doc.translate(tbl)
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

def writeCSV(df, fileOut):
	print("writing csv...")
	df.to_csv(fileOut, encoding='utf-8-sig', index=False)
	print("Wrote to", fileOut)

def tokenizeCSV(fileIn='../checkset-fixed.csv', colN=2):
	mydf = csv_to_df(fileIn)
	#bankdf = np.array(csv_to_df('../bank_words_cat_only.csv'))
	numProcesses = mp.cpu_count() #4
	pool = mp.Pool(processes = numProcesses)
	test = pool.map(kiwi_tokenizer, mydf.iloc[:, colN])
	#test = pool.map(kiwi_tokenizer, bankdf[:, 0])
	pool.close()
	pool.join()
	joined = [' '.join(i) for i in test]
	mydf.iloc[:, colN] = joined
	#bankdf[:, 0] = joined
	print("Done!")
	return(mydf)

if __name__ == "__main__":
	textCol = 1
	print("tokenizing corpora...")
	#corpora = tokenizeCSV('../../kcna-full-plsbeutf8.csv', colN=3)
	start = time()
	#corpora = tokenizeCSV(fileIn='../../top_articles_txt.csv', colN=textCol)
	corpora = tokenizeCSV()
	end = time()
	print("Done! Took", end-start)
	writeCSV(corpora, 'tokenoutkiwi.csv')