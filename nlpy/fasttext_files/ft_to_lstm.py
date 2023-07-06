import fasttext
from unicodedata import normalize
import pandas as pd
import numpy as np
from tensorflow import keras
from keras.models import Model, load_model, Sequential
from keras.layers import Dense, Input, Dropout, LSTM, Activation, Bidirectional
from keras.layers import Embedding
from keras.utils import pad_sequences
from keras.initializers import glorot_uniform
#from keras.preprocessing.text import Tokenizer
from keras.callbacks import ModelCheckpoint, EarlyStopping
from keras.regularizers import l1, l2
from keras.optimizers import Adam
from sklearn.model_selection import train_test_split

def excel_to_df(filename, skip_header=False):
	df = []
	if(skip_header):
		pd_header = None
	else:
		pd_header = 0
	df = pd.read_excel(filename, dtype='unicode', header=pd_header)
	return df

train_df = excel_to_df("shield_train.xlsx")
test_df = excel_to_df("shield_test.xlsx")
train_df['category'] = [1 if x == "shield" else 0 for x in train_df['category']]
test_df['category'] = [1 if x == "shield" else 0 for x in test_df['category']]

data = pd.concat([train_df, test_df])
#um... I guess just knowing that the first len(train_df) rows are train and last len(test_df) are test...
data['word_len'] = data['sentence'].apply(lambda x: len(x.split()))
MAX_SEQUENCE_LENGTH = max(data['word_len']) #which is like 82
#mean sentence length of about 20 words (true for unseen as well)
#hm.. for now set max_seq_len to max(data['word_len'])

#I think ft_model.get_sentence_vector() plus some padding/chopping too-long sentences should function as a tokenizer. lol.
ft_model = fasttext.load_model("ft_shield.bin")

with open("vocab.txt", "r", encoding="utf-8") as f:
	myVocab = [s.strip() for s in f.readlines()]

vector_length = ft_model.get_dimension() #300
#word_index = ft_model.get_words(on_unicode_error='replace')
#want word_index to be words that we see in our used text only
#otherwise using all 200000 words in the og fasttext .bin
#and then I run out of RAM

def f():
	#...except this bricks the indexing, I think...
	#or maybe it doesnt otherwise this wouldve bricked earlier?
	#Still doesn't explain why it performs even worse without the fasttext
	vocab_size = len(myVocab)
	print("vocab size:", vocab_size)
	embedding_matrix = np.random.random((vocab_size, vector_length))
	for i in range(vocab_size):
		word = myVocab[i]
		try:
			embedding_vector = ft_model.get_word_vector(word)
		except:
			print(word, "not found")
		if embedding_vector is not None:
			embedding_matrix[i, :] = embedding_vector

	#why arent you using a hash table?
	#key: ft_model.get_word_id
	#value: index in myVocab
	#so that it matches the embedding_matrix. lol...
	my_hash_table = {k:v  for (v, k) in enumerate([ft_model.get_word_id(x) for x in myVocab])}

	sequences = data['sentence'].map(lambda sent: [my_hash_table.get(ft_model.get_word_id(x), 0) for x in sent.split()]) #? I think its just the way np prints...
	#^ idt the indexing with get_word_id and myVocab is matching up.
	tokenized = pad_sequences(sequences, maxlen=MAX_SEQUENCE_LENGTH, padding='post')

def g():
	word_index = ft_model.get_words(on_unicode_error='replace')
	vocab_size = len(word_index)
	print("vocab size:", vocab_size)
	embedding_matrix = np.random.random((vocab_size, vector_length))
	for i in range(vocab_size):
		word = word_index[i]
		try:
			embedding_vector = ft_model.get_word_vector(word)
		except:
			print(word, "not found")
		if embedding_vector is not None:
			embedding_matrix[i, :] = embedding_vector

print("ok...")

def build_model1():
    sentence_indices = Input(shape=(MAX_SEQUENCE_LENGTH,), dtype='int32')
    
    embeddings = Embedding(input_dim=vocab_size, output_dim=300, weights=[embedding_matrix])(sentence_indices)      

    X = Bidirectional(LSTM(units = 512, kernel_regularizer=l1(0.000001), return_sequences = True))(embeddings)   #, dropout=0.05, recurrent_dropout=0.15 , return_sequences = True
    X = Dropout(rate = 0.2)(X)
    X = Bidirectional(LSTM(units = 256, kernel_regularizer=l1(0.000001), return_sequences = True))(X)   #, dropout=0.05, recurrent_dropout=0.15 , return_sequences = True
    X = Dropout(rate = 0.2)(X)
    X = Bidirectional(LSTM(units = 128, kernel_regularizer=l1(0.000001)))(X)   #, dropout=0.05, recurrent_dropout=0.15 , return_sequences = True
    X = Dropout(rate = 0.2)(X)
    #X = GlobalMaxPooling1D()(X)
    X = Dense(128, activation='relu')(X)
    X = Dense(1, activation='sigmoid')(X)
    
    model = Model(inputs=sentence_indices, outputs=X)
    
    return model

#model = build_model1()
model = Sequential()
#model.add(Embedding(input_dim = vocab_size, output_dim=300, weights=[embedding_matrix]))
model.add(Embedding(input_dim = vocab_size, output_dim=300, weights=[embedding_matrix]))
#model.add(Embedding(input_dim = vocab_size, output_dim=300))
model.add(LSTM(300, dropout=0.2, recurrent_dropout=0.2))
model.add(Dense(1, activation='sigmoid'))

print("ok...")

train_data = tokenized[:train_df.shape[0],]
print("train_data shape:", train_data.shape)
X_train_val, X_test, Y_train_val, Y_test = train_test_split(train_data, train_df["category"].values, test_size=0.1, random_state=42)
X_train, X_val, Y_train, Y_val = train_test_split(X_train_val, Y_train_val, test_size=0.1, random_state=42)
#in this case, t*_data is the tokenized+padded data
#and t* without anything at the end is the raw

model.compile(loss='binary_crossentropy',optimizer='adam',metrics=['accuracy'])

earlyStopping=EarlyStopping(monitor='val_accuracy',min_delta=0,patience=0,verbose=1,mode='auto')
history = model.fit(X_train, Y_train, batch_size=16, epochs=5, validation_data = (X_val, Y_val), callbacks=[earlyStopping], shuffle=True)
#why is it so fucking bad? something is wrong.
#it's basically performing no better/even worse than the null model

model.evaluate(X_test,Y_test,batch_size=16)