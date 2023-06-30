
from time import time
import fasttext
import numpy as np
#import fasttext.util

#fasttext.util.download_model('ko', if_exists='ignore')
#ft = fasttext.load_model('cc.ko.300.bin')

#vector_length = 100

# # original BIN model loading
# f = fasttext.load_model('cc.ko.300.bin')
# if vector_length < 300:
# 	fasttext.util.reduce_model(f, vector_length) #STOP BRICKING MY COMPUTER
# end = time()
# print("Took", end-start, "to load model of vector length", vector_length)

# # get all words from model
# words = f.get_words(on_unicode_error='replace')

# with open('fasttextko.vec','w') as file_out:
    
#     # the first line must contain number of total words and vector dimension
#     file_out.write(str(len(words)) + " " + str(f.get_dimension()) + "\n")

#     # line by line, you append vectors to VEC file
#     for w in words:
#         v = f.get_word_vector(w)
#         vstr = ""
#         for vi in v:
#             vstr += " " + str(vi)
#         try:
#             file_out.write(w + vstr+'\n')
#         except:
#             pass
# print("Done writing vec.")
#idk why I did this and it still thinks dimension 100? 
# start = time()
# ft_model = fasttext.train_supervised('shielddata.txt', pretrainedVectors='fasttextko.vec') 
# end = time()
#print("Took", end-start, "to train_supervised.")
#print("Saving...")
#ft_model.save_model("testmodel.bin")

ft_model = fasttext.load_model("testmodel.bin")

vector_length = ft_model.dim #100 i think
#word_index = tokenizer.word_index #?
word_index = ft_model.get_words()
vocab_size = len(word_index) #+ 1 ..?
embedding_matrix = np.random.random((vocab_size, vector_length))
for i in range(vocab_size):
	word = word_index[i]
	try:
		embedding_vector = ft_model.get_word_vector(word)
	except:
		print(word, "not found")
	if embedding_vector is not None:
		embedding_matrix[i, :] = embedding_vector