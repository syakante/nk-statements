import fasttext
import re
import lime.lime_text
import pandas as pd
import numpy as np
#from pathlib import Path
from collections import Counter

def excel_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_excel(filename, dtype='unicode', header=pd_header)
	return df

def tokenize_string(s):
	return s.split()

def ft_pred_format(classifier, texts):
	#since Im using binary classifier,
	#p(q) = 1-p(n)
	#but eh... well...idk how this works tbh
	res = []
	labels, probs = classifier.predict(texts, 2)
	for l, p, text in zip(labels, probs, texts):
		order = np.argsort(np.array(l))
		res.append(p[order])
	return(np.array(res))

def my_explain_instance(text):
	global explainer
	global ft_model
	exp = explainer.explain_instance(
		text,
		classifier_fn = lambda x: ft_pred_format(ft_model, x),
		num_features=20
	)
	return(exp)

def explain_text(text):
	global explainer
	global ft_model
	exp = explainer.explain_instance(
		text,
		classifier_fn = lambda x: ft_pred_format(ft_model, x),
		num_features=20
		#i think avg sent is ~20 long anyway
	)
	item = Counter()
	for k, v in exp.as_list():
		item[k] += v
	return item

#tmp = my_explain_instance("이것 병진 보검 더욱 억세 틀 쥐 원쑤 가증 위협 으로부터 조국 인민 안전 확고히 담보 선제 핵공격 능력 천 백 배 강화 나가 주체 조선 철 선언 였")
#tmp.save_to_file("explanation.html")

print("ok")



def get_feats_for_label(inpath:str, label:str):

	modelname = "ft_"+label+".bin"
	global ft_model
	ft_model = fasttext.load_model(modelname)

	global explainer
	explainer = lime.lime_text.LimeTextExplainer(
		split_expression=tokenize_string,
		bow=False, #if true, unigrams only
		class_names=["not"+label, label] #0, 1...?
		)

	data = Counter()
	
	sent_df = excel_to_df(inpath)
	sent_df = sent_df[sent_df['category'] == label]
	print("Getting features from", sent_df.shape[0], "sentences.")

	for i in range(len(sent_df['sentence'])):
		sent = sent_df['sentence'].iloc[i]
		print(i)
		c = explain_text(sent)
		data.update(c)

	df = pd.DataFrame.from_dict(data, orient='index').reset_index()
	df = df.sort_values(0)
	df.columns = ['word', 'score']
	df.score /= sent_df['sentence'].apply(lambda s: len(s.split()))
	print(df)
	df.to_excel(label+"_wordweights.xlsx")

#get_feats_for_label("../../shield-1998-2011.xlsx", "shield")
get_feats_for_label("../../shield-2012-2023.xlsx", "shield")
#but close repl cuz aiieee ram