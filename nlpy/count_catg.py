from collections import Counter
from unicodedata import normalize
import csv
import pandas as pd
import itertools
from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords
import multiprocessing as mp
from time import time

k = Kiwi()
k_sw = Stopwords()

with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
    stopwords = set(f.read().split())

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

def csv_to_df(filename='../checkset-fixed.csv', skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_csv(filename, dtype='unicode', header=pd_header, encoding='utf8')
	return df

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

def countCatMatches(inTuple):
	#given a single corpus
	#I guess... iter thru words
	#and count how many times a word of each category appeared in that corpus
	#...
	i, doc = inTuple
	global word_catg
	this_doc_word_counts = { 'sword': 0, 'shield': 0, 'badge': 0 }
	#corpL = doc.split(' ')
	for bankword in word_catg.keys():
		if bankword in doc:
			this_doc_word_counts[word_catg[bankword]] = this_doc_word_counts[word_catg[bankword]]+1
	this_doc_word_counts['id'] = i
	return pd.DataFrame([this_doc_word_counts], columns = this_doc_word_counts.keys())

def init_worker(shared_d):
	global word_catg
	word_catg = shared_d

def make_dict(pd_df):
	global word_catg
	word_catg = dict(itertools.zip_longest(pd_df.iloc[:, 1], pd_df.iloc[:, 2]))

if __name__ == "__main__":
	textCol = 3
	bank_tokenized = csv_to_df('../bank_words_tokenized.csv') #dont care abt col 0
	print("got bank_tokenized")
	make_dict(bank_tokenized)
	print("got word_catg")
	print("tokenizing corpora...")
	start = time()
	corpora = tokenizeCSV('../../kcna-full-plsbeutf8.csv', colN=textCol)
	#corpora = tokenizeCSV('toydata.csv', colN=textCol)
	end = time()
	print("Tokenized corpora. Took", end-start)
	numProcesses = mp.cpu_count() #4
	pool = mp.Pool(processes = numProcesses, initializer = init_worker, initargs = (word_catg,))
	print("counting category matches...")
	start = time()
	test = pool.map(countCatMatches, zip(corpora.iloc[:,0],corpora.iloc[:,textCol]))
	pool.close()
	pool.join()
	end = time()
	#print(pd.concat(map(countCatMatches, zip(corpora.iloc[:,0],corpora.iloc[:,3]))))
	print("Done! Took", end-start)
	writeCSV(pd.concat(test), 'aiieeeeee.csv')