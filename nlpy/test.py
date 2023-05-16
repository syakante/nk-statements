from collections import Counter
from unicodedata import normalize
import re

from konlpy.corpus import kolaw
from konlpy.tag import Hannanum
from konlpy.utils import concordance, pprint
from matplotlib import pyplot
from mecab import MeCab

def draw_zipf(count_list, filename, color='blue', marker='o'):
    sorted_list = sorted(count_list, reverse=True)
    pyplot.plot(sorted_list, color=color, marker=marker)
    pyplot.xscale('log')
    pyplot.yscale('log')
    pyplot.savefig(filename)

with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
    stopwords = f.read().split("\n")

with open('punct.txt', mode='r', encoding='utf-8') as f:
    punct = f.read().replace('\n', '')

#watch out for encoding problems.......
with open('example shield article.txt', mode='r', encoding = 'utf-8') as f:
    doc = f.read()
doc = normalize("NFKC", doc)
#tbl = str.maketrans('', '', punct)
tbl = str.maketrans(punct, ' '*len(punct))
doc = doc.translate(tbl)
h = Hannanum()
#m = Mecab(dicpath=r"C:/mecab/mecab-ko-dic")
m = MeCab()
h_morphs = h.morphs(doc)
h_morphs2 = [word for word in h_morphs if word not in stopwords]
m_morphs = m.morphs(doc)
m_morphs2 = [word for word in m_morphs if word not in stopwords]
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
