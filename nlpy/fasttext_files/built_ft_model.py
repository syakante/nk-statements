
from time import time
import fasttext
import pandas as pd
import numpy as np
from unicodedata import normalize
#import fasttext.util

#fasttext.util.download_model('ko', if_exists='ignore')
#ft = fasttext.load_model('cc.ko.300.bin')

# vector_length = 100

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
#^^^ i have no idea what this is actually

label = "sword"

trainfile = label+"_train.txt"
testfile = label+"_test.txt"

start = time()
ft_model = fasttext.train_supervised(trainfile, dim=300, pretrainedVectors='cc.ko.300.vec', epoch=15, minCount=2, bucket=20000,thread=8)
#took out wordNgrams param for now cuz uh... gonna use for lstm later I guess 
end = time()
print("Took", end-start, "to train_supervised.")
#takes like btwn 200-300 secs?

print("on train data:")
print(ft_model.test(trainfile))
print("on test data:")
print(ft_model.test(testfile))

print("Saving...")
binfile = "ft_"+label+".bin"
ft_model.save_model(binfile)
#in the future, try out quantize
#got 0.6933333333333334 on test data (cringe!)

# ft_model = fasttext.load_model("testmodel.bin")
# print("Loaded model.")

####
#ok just trying with first round of ft only
#for the record, ft base is a shallow nn
#no lstm nn etc yet...
# predictions = []
# with open("unseen-sentences-tokenized.txt", "r", encoding="utf-8") as f:
	# for line in f:
	# 	try:
	# 		s = normalize("NFKC", line.rstrip())
	# 		tmp = ft_model.predict(s)
	# 		label = tmp[0][0][9:]
	# 		prob = tmp[1][0]
	# 		predictions.append([label, prob])
	# 	except:
	# 		print("Something went wrong.")

# print("Done predicting.")
# print("Writing...")
# df = pd.DataFrame(predictions)
# df.to_csv("unseen-predictions.csv", sep=",")
# print("Done!")

####