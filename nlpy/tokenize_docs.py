from unicodedata import normalize
import pandas as pd
from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords
import multiprocessing as mp
from time import time
import argparse

#UNBELIEVABLY BRICKED. AUGHHHH

def csv_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_csv(filename, dtype='unicode', header=pd_header, encoding='utf8')
	return df

def excel_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_excel(filename, dtype='unicode', header=pd_header)
	return df

def kiwi_tokenizer(doc:str): #->List[str]
	try:
		print("normalizing encoding...", end = " ")
		doc = normalize("NFKC", doc)
	except:
		print("Something went wrong.")
		return []
	print("removing punctuation...", end = " ")
	doc = doc.translate(tbl)
	print("tokenizing with Kiwi...", end = " ")
	try:
		kiwi_tokens = k.tokenize(doc, stopwords=k_sw) #--> List of Token objects. We're interested in .form attribute
	except:
		print("???")
	#In the future, should add some kind of catch here for when a doc causes kiwi to crash for whatever reason...
	kiwi_words = [t.form for t in kiwi_tokens]
	#print("ok")
	print("manual prefix adjustment...", end = " ")
	clean_tokens = []
	i=0
	while i < len(kiwi_words):
		token = kiwi_words[i]
		if len(token) < 0:
			#idt this would happen
			print("Something went wrong.")
			i += 1
			continue
		if(kiwi_words[i] == "핵"):
			if(i < len(kiwi_words)-1):
				#print("attached 핵.", end = " ")
				token = kiwi_words[i] + kiwi_words[i+1]
				i += 1
			else:
				#print("somehow found 핵 by itself at the end of the document.")
				#print(clean_tokens[-1])
				pass
		clean_tokens.append(token)
		i += 1
	print("Done tokenizing a doc!")
	return(' '.join(clean_tokens))


def myWrapper(indeces):
	textCol = 3
	start = indeces[0]
	stop = indeces[1]
	filename = '../../kcna-half-1.xlsx'
	if start == 0:
		subarray = pd.read_excel(filename, dtype='unicode', header=0, skiprows=range(start),nrows=stop-start)
	else:
		subarray = pd.read_excel(filename, dtype='unicode', header=None, skiprows=range(start+1),nrows=stop-start)
	#+1 bc of header
	print("Read file: from",start,"to", stop)
	idekanymore = list(map(kiwi_tokenizer, subarray.iloc[:,textCol]))
	subarray.iloc[:,textCol] = idekanymore
	return(subarray)


def initializer():
	with open('punct.txt', mode='r', encoding='utf-8') as f:
		punct = f.read().replace('\n', '')
	global tbl
	tbl = str.maketrans(punct, ' '*len(punct))
	print("importing custom words to kiwi...")
	global k
	k = Kiwi()
	myWords = csv_to_df('customWords.csv')
	for i in range(myWords.shape[0]):
		#print("adding", myWords.iloc[i,0])
		k.add_user_word(word=myWords.iloc[i,0], tag=myWords.iloc[i,1])
	global k_sw
	k_sw = Stopwords()
	k_sw.remove(('없', 'VA'))
	k_sw.remove(('우리','NP'))
	k_sw.remove(('더','MAG'))


def writeCSV(df, fileOut):
	print("writing csv...")
	df.to_csv(fileOut, encoding='utf-8-sig', index=False)
	print("Wrote to", fileOut)


# from collections.abc import Iterable
# def flatten(xs):
# 	for x in xs:
# 		if isinstance(x, Iterable) and not isinstance(x, (str, bytes)):
# 			yield from flatten(x)
# 		else:
# 			yield x

def bank():
	start = time()
	textCol = 0
	
	raw = csv_to_df('../bank_words_cat_only.csv',skip_header=False)

	### tokenize (aiee mp)
	print("Tokenizing corpora...")
	numProcesses = mp.cpu_count() #4
	pool = mp.Pool(processes = numProcesses, initializer=initializer, initargs=())
	#out = pool.imap_unordered(kiwi_tokenizer, raw.iloc[:, textCol])
	out = pool.map(kiwi_tokenizer, raw.iloc[:, textCol])
	pool.close()
	pool.join()
	print("ok")
	raw.insert(1, "tokenized", out)
	print("ok2")
	
	writeCSV(raw, 'bank_tokenized_latest.csv')
	
	print("Done with text processing.")
	end = time()
	print("Done! Took", end-start)

def main(filename, textCol, outfile, headlineCol=-1, headlineFlag=False):
	#eh... potentially clean to work on arbitrary number of columns but not a priority for now
	start = time()
	# headlineCol = 0
	# textCol = 2
	# filename = '../march-to-june.xlsx'
	
	### read external file
	print("File:",filename)
	raw = excel_to_df(filename)

	### tokenize (aiee mp)
	print("Tokenizing corpora...")
	numProcesses = mp.cpu_count() #4
	pool = mp.Pool(processes = numProcesses, initializer=initializer, initargs=())
	text = pool.map(kiwi_tokenizer, raw.iloc[:, textCol])
	pool.close()
	pool.join()
	print("tokenized text.")
	raw.iloc[:, textCol] = text
	print("ok.")
	
	if(headlineFlag):
		pool = mp.Pool(processes = numProcesses, initializer=initializer, initargs=())
		headlines = pool.map(kiwi_tokenizer, raw.iloc[:, headlineCol])
		pool.close()
		pool.join()
		print("tokenized headlines.")
		raw.iloc[:, headlineCol] = headlines
	

	print("Done with text processing.")
	raw.to_excel(outfile, index=False)
	end = time()
	print("Done! Took", end-start)

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description = "Tokenize the text docs in an excel file.")
	parser.add_argument("--input", "-i", type=str, required = True, help="Input Excel file.")
	parser.add_argument("--output", "-o", type=str, required = True, help="Output Excel file.")
	parser.add_argument("--text", "-t", type=int, required = True, help="Column number containing string docs you wish to tokenize.")
	args = parser.parse_args()
	main(filename=args.input, textCol=args.text, outfile=args.output)