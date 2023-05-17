from collections import Counter
from unicodedata import normalize
import csv
import re

from matplotlib import pyplot
from mecab import MeCab
#from konlpy.tag import Hannanum, Kkma, Komoran, Okt
from konlpy.tag import Okt

with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
    stopwords = f.read().split("\n")

stopwords = set(stopwords)

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

df = []

# def my_sub(m):
#     return '' if m.group() in stopwords else m.group()

# m = MeCab()
# h = Hannanum()
# kk = Kkma()
# k = Komoran()
o = Okt()
#my_pointers = {"m": m, "h": h, "k": k, "o": o}

def my_cleaner(s:str, which_tagger="o")->str:
    s = normalize("NFKC", s)
    #s1 = ' '.join(my_pointers[which_tagger].morphs(s))
    s1 = ' '.join(o.morphs(s)) #<-- this was for printing purposes. In future work it should stay a list. I think...
    s2 = re.sub(r'\S+', lambda m: '' if m.group() in stopwords else m.group(), s1) #lmao 
    if(s2 != s1):
        print(s, "-->", s1, "-->", s2)
    return s2

def my_main(which_tagger="o"):
    #watch out for encoding problems.......
        with open('../bank_words_cat_only.csv', encoding = 'utf-8') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=",")
            #next(csvreader) #skip header
            seen = set()
            i = 0 #le excel 1 indexing
            for row in csvreader:
                i += 1
                if row[0] in seen:
                    continue
                else:
                    seen.add(row[0])
                    df.append([i, my_cleaner(row[0], which_tagger), row[1]])

def clean_tokens(L):
    #aiiieeeeeeeeeeetokenization troublesome bc of the way kr works differently from eng...
    #specifically roadblocked by there not being any reliable way to detect if "haek" is at the end or beginning of a phrase (e.g. haek for haek)
    #though 99% of the time it's a prefix
    #most attach "haek" to nearest word
    #but only if it's not EOL, i.e. left-to-right only
    #In the future I want to use this function on whole articles
    #because the point is to tokenize the corpus, not just this word bank (pretty sure this was more of a sample....)
    #anyway try it out on a full article see what it looks like
    pass

#which_taggers_L = ["m", "h", "kk", "k", "o"]
my_main("o") #using Okt because it seems to preserve the most...
#kkoma bricks my computer so can't use that. lol.
for r in df:
    print(r)
#interesting where "은" could be a stopword or mean silver or sth but idk how to identify that. POS???

#pos = o.pos(doc)
#cnt = Counter(pos)

# print('nchars  :', len(doc))
# print('ntokens :', len(doc.split()))
# print('nmorphs :', len(set(pos)))
# print('\nTop 5 frequent morphemes:'); pprint(cnt.most_common(5))
#print('\nLocations of "국방" in the document:')
#concordance(u'국방', doc, show=True)
