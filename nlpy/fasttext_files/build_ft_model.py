from time import time
import fasttext
import pandas as pd
import numpy as np
from unicodedata import normalize
import argparse

import fasttext.util

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

#label = "badge"

def train_pretrained(label:str):
	trainfile = label+"_train.txt"
	testfile = label+"_test.txt"
	print("(Assuming cc.ko.300.vec already exists)")
	#fasttext.util.download_model('ko', if_exists='ignore')
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

def train_scratch(label:str):
	#given the limited data, this model performs too poorly to be considered, tbh.
	trainfile = label+"_train.txt"
	testfile = label+"_test.txt"

	start = time()
	ft_model = fasttext.train_supervised(trainfile, dim=300, epoch=15, minCount=2, bucket=2000, thread=8)
	#took out wordNgrams param for now cuz uh... gonna use for lstm later I guess 
	end = time()
	print("Took", end-start, "to train_supervised.")
	#takes like btwn 200-300 secs?

	print("on train data:")
	print(ft_model.test(trainfile))
	print("on test data:")
	print(ft_model.test(testfile))

	print("Saving...")
	binfile = "ft_"+label+"scratch.bin"
	ft_model.save_model(binfile)


#in the future, try out quantize
#got 0.6933333333333334 on test data (cringe!)
#and any hyperparameter changes don't seem to affect it. ...
#for sword got .8266 (inch resting)
#and badge got .78 (inch resting...)

def excel_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_excel(filename, dtype='unicode', header=pd_header)
	return df

####
#ok just trying with first round of ft only
#for the record, ft base is a shallow nn
#no lstm nn etc yet...
def predict_one(s:str, model):
	try:
		s = normalize("NFKC", s.strip())
		tmp = model.predict(s)
		#print("yahoo!")
		label = tmp[0][0][9:]
		prob = tmp[1][0]
		return([label, prob])
	except:
		print("Something went wrong.")
		return(["NA", 0])

def predict(label:str, infile:str):
	infile = "ft_"+label+".bin"
	ft_model = fasttext.load_model(infile)
	unseen = excel_to_df(infile)
	predictions = [predict_one(sent, ft_model) for sent in unseen['sentence']]
	print("Done predicting.")
	print("Writing...")
	df = unseen.join(pd.DataFrame(predictions))
	df.drop('sentence', axis=1)
	df.to_excel("unseen-predictions-"+label+".xlsx")
	print("Done!")


if __name__ == "__main__":
	parser = argparse.ArgumentParser(description = "Train or predict with the specified model (sword, shield, or badge).")
	parser.add_argument("--label", "-l", type=str, required = True, help="The label to use for training or prediction (sword, shield, badge).")
	
	subparsers = parser.add_subparsers(title="subcommands", dest="command")
	
	train_parser = subparsers.add_parser("train", help="Train the model with either pretrained vectors (cc.ko.300.vec) or from scratch.")
	train_parser.add_argument("--train_mode", "-m", type=str, choices = ["scratch", "pretrained"], required = True, help="Training mode: 'scratch' or 'pretrained'")

	predict_parser = subparsers.add_parser("predict", help = "Predict sentence classes with a trained model (sword, shield, badge).")
	predict_parser.add_argument("--input", "-i", type=str, required = True, help="Input xlsx file containing docs to predict on. (Currently, the name of the column containing docs must be 'sentence'.)")

	args = parser.parse_args()

	if args.command == "train":
		if(args.train_mode == "scratch"):
			train_scratch(args.label)
		elif(args.train_mode == "pretrained"):
			train_pretrained(args.label)
		else:
			parser.print_help()
	elif args.command == "predict":
		predict(args.label, args.input)
	else:
		parser.print_help()
		print("hint: --label goes first, then train/predict")

####

#train_scratch("shield")
#train_pretrained("shield")
#train_pretrained("sword")
#train_pretrained("badge")

#predict("shield")
#predict("sword")
#predict("badge")