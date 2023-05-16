from collections import Counter
from unicodedata import normalize
import csv
import re

from matplotlib import pyplot
from mecab import MeCab
from konlpy.tag import Hannanum, Kkma, Komoran, Okt

with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
    stopwords = f.read().split("\n")

stopwords = set(stopwords)

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

df = []

# def my_sub(m):
#     return '' if m.group() in stopwords else m.group()

m = MeCab()
h = Hannanum()
#kk = Kkma()
k = Komoran()
o = Okt()
#my_pointers = {str(i):i for i in [m, h, kk, k, o]} #:(
#my_pointers = {"m": m, "h": h, "kk": kk, "k": k, "o": o}
my_pointers = {"m": m, "h": h, "k": k, "o": o}

def my_cleaner(s:str, which_tagger)->str:
    s = normalize("NFKC", s)
    s1 = ' '.join(my_pointers[which_tagger].morphs(s))
    s2 = re.sub(r'\S+', lambda m: '' if m.group() in stopwords else m.group(), s1) #lmao 
    if(s2 != s1):
        print(s, "-->", s1, "-->", s2)
    return s2

def my_main(which_tagger):
    #watch out for encoding problems.......
        with open('nk-statements/bank_words_cat_only.csv', encoding = 'utf-8') as csvfile:
            csvreader = csv.reader(csvfile, delimiter=",")
            next(csvreader) #skip header
            seen = set()
            for row in csvreader:
                if row[0] in seen:
                    continue
                else:
                    seen.add(row[0])
                    df.append([my_cleaner(row[0], which_tagger), row[1]])

#which_taggers_L = ["m", "h", "kk", "k", "o"]
which_taggers_L = ["m", "h", "k", "o"]
for s in which_taggers_L:
    print(s, "here")
    my_main(s)

#kkoma bricks my computer so can't use that. lol.

#interesting where "은" could be a stopword or mean silver or sth but idk how to identify that. POS???
#--> to also 

#pos = Hannanum().pos(doc)
#cnt = Counter(pos)

# print('nchars  :', len(doc))
# print('ntokens :', len(doc.split()))
# print('nmorphs :', len(set(pos)))
# print('\nTop 5 frequent morphemes:'); pprint(cnt.most_common(5))
#print('\nLocations of "국방" in the document:')
#concordance(u'국방', doc, show=True)
