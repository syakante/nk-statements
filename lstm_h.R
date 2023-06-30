library(tidyverse)
library(dplyr)
library(keras)
library(stringi)
library(readxl)
library(tidytext)

#tensorflow::tf_config()
#use_condaenv("keras-tf", required = T)

dir = getwd()
raw <- read_excel(paste(dir,"//sampleset.xlsx", sep=""))
raw <- rename(raw, headline = "headline-tokenized")
raw$headline <- raw$headline %>% stri_replace(replacement="", regex="로동신문\\S*\\s|조선중앙통신\\S*\\s")
raw$category <- as.factor(raw$category)
maxLen = max(stri_length(raw$headline))

row_data <- nrow(raw) #155
set.seed(0)
#index <- sample(row_data, row_data*0.8)
train.df <- raw
#train.df <- raw[index,]
#test.df <- raw[-index,]
#table(train.df$category) %>% prop.table

num_words <- train.df$headline %>% paste(collapse = " ") %>% str_split(" ") %>% unlist() %>% n_distinct
#581 in this train, 666 distinct words total. spooky!
#raw %>% unnest_tokens(word, text) %>% count(word, sort=T)
tokenizer <- text_tokenizer(num_words = num_words) %>% fit_text_tokenizer(train.df$headline)

train.x <- texts_to_sequences(tokenizer, train.df$headline) %>% pad_sequences(maxlen = maxLen, padding="pre", truncating="post")
#test.x <- texts_to_sequences(tokenizer, test.df$headline) %>% pad_sequences(maxlen = maxLen, padding="pre", truncating="post")

labels <- raw$category %>% as.numeric %>% to_categorical
labels <- labels[,2:4]
#badge: col 1
#shield: col 2
#sword: col 3

tensorflow::tf$random$set_seed(0)

epochs <- 9
batch_size = 64

sw.model <- keras_model_sequential(name = "lstm_model") %>%
  layer_embedding(name = "input",
                  input_dim = num_words,
                  input_length = maxLen,
                  output_dim = 8) %>%
  layer_lstm(name = "LSTM",
             units = 8,
             kernel_regularizer = regularizer_l1_l2(l1 = 0.05, l2 = 0.05),
             return_sequences = F) %>%
  layer_dense(name = "Output",
              units = 1,
              activation = "sigmoid")

sw.model %>% compile(optimizer = "adam",
                     metrics = "accuracy",
                     loss ="binary_crossentropy")

sw.train_history <- sw.model %>% fit(x = train.x, y = labels[index,3],
                                     batch_size = batch_size,
                                     epochs = epochs,
                                     validation_split = 0.1,
                                     verbose = 1,
                                     view_metrics = 0)

plot(sw.train_history) + geom_line()
#um...

sh.model <- keras_model_sequential(name = "lstm_model") %>%
  layer_embedding(name = "input",
                  input_dim = num_words,
                  input_length = maxLen,
                  output_dim = 8) %>%
  layer_lstm(name = "LSTM",
             units = 8,
             kernel_regularizer = regularizer_l1_l2(l1 = 0.05, l2 = 0.05),
             return_sequences = F) %>%
  layer_dense(name = "Output",
              units = 1,
              activation = "sigmoid")

sh.model %>% compile(optimizer = "adam",
                     metrics = "accuracy",
                     loss ="binary_crossentropy")

sh.train_history <- sh.model %>% fit(x = train.x, y = labels[,2], #remember to add index back in for train/test split
                                     batch_size = batch_size,
                                     epochs = epochs,
                                     validation_split = 0.1,
                                     verbose = 1,
                                     view_metrics = 0)

plot(sh.train_history) + geom_line()

#REALLY BAD.jpg