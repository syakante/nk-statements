# from collections import Counter
# from unicodedata import normalize
# import re

# from konlpy.tag import Okt

import multiprocessing as mp
from time import sleep, time

def task(data):
    global d
    sleep(1)
    try:
        v = d[data]
        result = 1/v
        return result
    except:
        print(f"error")
        return None

def init_worker(shared_d):
    global d
    d = shared_d

def make_dict(n):
    global d
    d = { i: i for i in range(n, -1, -1)}

if __name__ == '__main__':
    make_dict(5)
    L = [0, 1, 2, 3, 4, 5]
    print("with mp:")
    num_proc = mp.cpu_count()
    pool = mp.Pool(processes = num_proc, initializer = init_worker, initargs=(d,))
    start = time()
    results = pool.map(task, L)
    pool.close()
    pool.join()
    end = time()
    print(results)
    print(end-start)
    print("without mp:")
    start = time()
    results = map(task, L)
    print(list(results))
    end = time()
    print(end-start)


# with open('stopwords-ko.txt', mode='r', encoding='utf-8') as f:
#     stopwords = set(f.read().split())

# with open('punct.txt', mode='r', encoding='utf-8') as f:
#     punct = f.read().replace('\n', '')

# #watch out for encoding problems.......
# with open('../../example shield article.txt', mode='r', encoding = 'utf-8') as f:
#     doc = f.read()
# doc = normalize("NFKC", doc)
# #tbl = str.maketrans('', '', punct)
# tbl = str.maketrans(punct, ' '*len(punct))
# doc = doc.translate(tbl)
# o = Okt()
# o_morphs = o.morphs(doc)
# o_morphs2 = [word for word in o_morphs if word not in stopwords]
# del(o_morphs)
# #interesting where "은" could be a stopword or mean silver or sth but idk how to identify that. POS???
# #or just manually add some missed stopwords after a few trials

# #basically just need to watch out for "핵 에는 핵" (from "핵에는 핵으로")
# #because if we do the following V without accounting for this edge case we'll get some haek-somethingunintended token
# #therefore if we find haek and the previous token(s) (if possible) compose "핵 에는", then combine that whole token into one
# #since we're processing it left to right, it's more like if we encounter haek and the last haek token we just merged was "핵 에는"
# #otherwise if find standalone haek token, attach it to the next token
# #and all other tokens are just the morphs from Okt.
# #anyway once we finish tokenizing you can do other more interesting things (embeddings??????!!!!!)

# clean_tokens = []

# i=0
# while i < len(o_morphs2):
#     token = o_morphs2[i]
#     if len(token) < 0:
#         #idt this would happen
#         print("h")
#         i += 1
#         continue
#     if(o_morphs2[i] == "핵"):
#         # if(i < len(o_morphs2)-1):
#         #     print("next token:", o_morphs2[i+1])
#         # else:
#         #     print("(no next token)")
#         # if(i > 0):
#         #     print("preceding token:", o_morphs2[i-1])
#         # else:
#         #     print("(no previous token)")
#         #^ though this won't happen because we attach to the following token anyway
#         if(i > 0 and clean_tokens[-1] == "핵에는"):
#             print("here")
#             clean_tokens[-1] = "핵에는 핵으로"
#             i += 1
#             continue
#         if(i < len(o_morphs2)-1):
#             token = o_morphs2[i] + o_morphs2[i+1]
#             i += 1
#         else:
#             print("somehow found haek by itself at the end of the document.")
#             print(clean_tokens[-1])
#     if(o_morphs2[i] == "론" and i < len(o_morphs2)-1 and o_morphs2[i+1][0] == "설"):
#         print("ok")
#         token = "론설"
#         o_morphs2[i+1] = o_morphs2[i+1][1:]
#         i += 1
#     clean_tokens.append(token)
#     i += 1

# #clean_tokens = [word for word in clean_tokens if word not in stopwords]