import pandas as pd
from unicodedata import normalize
from sklearn.model_selection import train_test_split

def excel_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_excel(filename, dtype='unicode', header=pd_header)
	return df

def write_df_txt(df, filename:str):
	#from pd df, write to fasttext compatible __label__whatever txt file
	print(df.shape)
	with open(filename, "w", encoding="utf-8") as f:
		for i in range(df.shape[0]):
			bss = "__label__"+df['category'].iloc[i]
			text = normalize("NFKC", df['sentence'].iloc[i])
			line = bss + " " + text + "\n"
			f.write(line)
	print("wrote", filename)

def main(label:str):
	mydf = excel_to_df("../../sentences-tokenized.xlsx")
	print("Read excel.")
	mydf['category'] = [label if x == label else "not"+label for x in mydf['category']]
	print("Mutated category.")
	train_df, test_df = train_test_split(mydf, test_size=0.2, stratify=mydf['category'], random_state=42)
	print("Stratified sampling.")
	#xlsx for posterity/use in R or whatever
	train_df.to_excel(label+"_train.xlsx")
	test_df.to_excel(label+"_test.xlsx")
	print("Wrote", label, "xlsx.")
	#txt for fasttext
	write_df_txt(train_df, label+"_train.txt")
	write_df_txt(test_df, label+"_test.txt")
	print("Wrote", label, "txt.")
	print("Done!")

main("sword")