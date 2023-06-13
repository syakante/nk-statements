library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(tidytext)
library(rsample)
library(doMC)
#library(text2vec)
library(keras)
library(ggplot2)

set.seed(0)

dir = getwd()
checkset <- read_excel(paste(dir,"//sampleset.xlsx", sep=""))
checkset <- checkset[!duplicated(checkset$id),]
checkset$category <- as.factor(checkset$category)
tokenized <- read_excel(paste(dir,"//nlpy//fulloutput.xlsx", sep="")) %>% subset(id %in% checkset$id) %>% select(id, text)
tokenized$id <- as.numeric(tokenized$id)

order <- match(checkset$id, tokenized$id)
tokenized <- tokenized[order,]
df <- merge(checkset, tokenized, by="id")

terms.v = c("우리 생존","대조선 핵선제공격","미국 핵선제공격","방패","우리 핵선제공격","핵위협 가증","핵악몽",
             "미국 핵전쟁 도발","미국 핵전쟁 도발 책동","외부 핵위협","평화 수호","정당방위","반핵","평화적핵",
             "핵선제공격 대상","핵전쟁 위협","침략 정책","북침 핵전쟁 연습","핵전쟁 발발","핵위협 공갈","방위력",
             "불장난","평화 환경","자위적","핵전쟁 책동","생존권","평화 보장","위협 당하","핵재난","전쟁광",
             "핵반격","전쟁 밖에","핵에는 핵으로","민족 생명","핵전투","핵타격 무장","핵공격 태세",
             "핵선제 타격 권","섬멸 포문","전멸","종국 파멸","핵공격 능력","핵무력 강화","경고","전투태세",
             "핵보검","전투준비태세","조미 핵대결 전","전쟁 상태","막을수 없","자멸","교전 관계","보복 타격",
             "주체 무기","위력한 보검","장검","정밀 핵타격 수단",
             "세계 앞","핵보유국 전렬","핵보유국 지위","핵강국 전렬","당당 핵보유국","최첨단핵","세기 기적",
             "국가 핵무력 완성","힘 대결","동방 핵강국","자랑 스럽","세상 없","신뢰성","세계 핵","조미 대결",
             "당황","힘찬 진군","공화국 핵무력","정의 핵억제력","기술 우세","대결 시대","전략 지위",
             "놀라","우리 식","초강도","더 위력한","무진 막강")
#removed "가하", from sword
#"힘 대결" appeared twice in badge fsr

doc_word_counter <- function(doc, term_vector){
  #in: single doc
  #out: vector of length unique(dict$terms) that counts which word appeared how many times
  return(vapply(term_vector, function(x){stri_count(doc, regex=x)}, numeric(1)))
}
ndocs <- dim(df)[1]
#get words with 핵 in them and count them
haek.terms <- df %>% unnest_tokens(word, text) %>% filter(stri_detect(word, regex="핵")) %>% count(word, sort=T) %>% filter(n > 10) %>% getElement("word")
haek.terms = haek.terms[ !haek.terms == ""]
our.bigrams <- df %>% unnest_tokens(bigram, text, token="ngrams", n=2) %>% filter(!is.na(bigram), stri_detect(bigram, regex="^우리\\s")) %>% count(bigram, sort=T) %>% filter(n > 5) %>% getElement("bigram")
terms.v <- c(terms.v, haek.terms, our.bigrams)
funvalue = length(terms.v)
word_freq_matrix <- data.frame(matrix(rep(0, ndocs*funvalue), nrow=ndocs, ncol=funvalue))
word_freq_matrix <- as.data.frame(t(vapply(df$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
word_freq_matrix <- word_freq_matrix %>% as.matrix
colnames(word_freq_matrix) <- terms.v
rownames(word_freq_matrix) <- df$id

#text analysis with headlines
#mytidy <- checkset %>% rename(text = `headline-tokenized`) %>% select(id, text) %>% unnest_tokens(word, text) %>% group_by(word) %>% filter(n() > 2) %>% ungroup()
h.terms.v <- c("미국","조선","남조선","군사","김정은","없","외무성","시험","도발","우리","자위적","전쟁","국제","나라","대결",
               "민주조선","전략","평화","핵전쟁","강화","규탄","보도","비서","연습","인사","조선반도","조치","지도","총",
               "핵무기","단죄","문제","비난","유엔","지지","핵무력","행위","회의","훈련","경고","권리","나가","대회","무모",
               "발사","방지","버리","병","북침","요구","위험","정당","정책","조국","진로","책임","타격","통일","행동","강조",
               "건설","검토","공동","공화국","괴뢰","국방위","기초","긴장","길","당","대조선","대화","못하","무기","민족","반",
               "비핵","상보","선군","성공","시비","실천","아시아","연구원","연설","옹호","외무상","위협","인민","조약","책동",
               "평론가","합동","핵군축","핵억제력")

funvalue = length(h.terms.v)
head_freq_matrix <- as.data.frame(t(vapply(df$`headline-tokenized`, function(x){doc_word_counter(doc=x, term_vector=h.terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
colnames(head_freq_matrix) <- sapply(h.terms.v, function(x){paste(x, "h", sep="_")}, USE.NAMES=F) %>% as.vector
rownames(head_freq_matrix) <- df$id

M <- cbind(word_freq_matrix, head_freq_matrix) %>% as.matrix

registerDoMC(cores=8)

# model <- keras_model_sequential()
# model %>% layer_dense(units = 64, activation = "relu", input_shape = c(ncol(word_freq_matrix)))
# model %>% layer_dense(units = 32, activation = "relu")
# model %>% layer_dense(units = 3, activation = "softmax") #units = num_classes
# 
# model %>% compile(
#   loss = "categorical_crossentropy",
#   optimizer = "adam",
#   metrics = c("accuracy")
# )

#one-hot encoding labels because......
labels <- df$category %>% as.numeric %>% to_categorical
labels <- labels[,2:4]
#col 1: badge; 2: shield; 3: sword

# model %>% fit(
#   x = word_freq_matrix,
#   y = labels,
#   batch_size = 32,
#   epochs = 10,
#   validation_split = 0.2
# )
#hm. The accuracy for this multi classifier is only slightly worse than the logistic one-vs-rest ones, so I'm hopeful that
#using NN with one-vs-rest will be even better. Also helps with weight readability too, I hope.

#sword
sw.model <- keras_model_sequential()
sw.model %>% layer_dense(units = 64, activation = "relu", input_shape = c(ncol(M)))
sw.model %>% layer_dense(units = 32, activation = "relu")
sw.model %>% layer_dense(units = 1, activation = "sigmoid")

sw.model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy")
)
sw.model %>% fit(
  x = M,
  y = labels[,3],
  batch_size = 32,
  epochs = 10,
  validation_split = 0.2
)
#pretty good! .84 acc, .74 val acc
#adding headline word matrix increased to .9 and .84. Yahoo!

#shield
sh.model <- keras_model_sequential()
sh.model %>% layer_dense(units = 64, activation = "relu", input_shape = c(ncol(M)))
sh.model %>% layer_dense(units = 32, activation = "relu")
sh.model %>% layer_dense(units = 1, activation = "sigmoid")

sh.model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy")
)
sh.model %>% fit(
  x = M,
  y = labels[,2],
  batch_size = 32,
  epochs = 10,
  validation_split = 0.2
)
#hm... .9 acc, .68 val acc
#adding headline matrix to .91, .71.

#badge
bd.model <- keras_model_sequential()
bd.model %>% layer_dense(units = 64, activation = "relu", input_shape = c(ncol(M)))
bd.model %>% layer_dense(units = 32, activation = "relu")
bd.model %>% layer_dense(units = 1, activation = "sigmoid")

bd.model %>% compile(
  loss = "binary_crossentropy",
  optimizer = "adam",
  metrics = c("accuracy")
)
bd.model %>% fit(
  x = M,
  y = labels[,1],
  batch_size = 32,
  epochs = 10,
  validation_split = 0.2
)

#...this didn't do as well as I expected. only .6 val acc?!
#it got worse?! .86, .58?!

save_model_hdf5(sw.model, "swordmodel")
save_model_hdf5(sh.model, "shieldmodel")
save_model_hdf5(bd.model, "badgemodel")

## trying on the rest of the unseen data
#TODO: currently the selection from raw is by mentions of haek but this isn't a good filter bc not all haek is useful...
#so update that to has keyword instead
raw <- read_excel(paste(dir,"//selected-w-headlines.xlsx", sep=""))
raw$Date <- as.Date(raw$Date, format="%Y-%m-%d")
raw$id <- as.numeric(raw$id)

funvalue = length(terms.v)
unseen_1 <- as.data.frame(t(vapply(raw$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
unseen_1 <- unseen_1 %>% as.matrix
colnames(unseen_1) <- terms.v
rownames(unseen_1) <- raw$id

funvalue = length(h.terms.v)
unseen_2 <- as.data.frame(t(vapply(raw$headline, function(x){doc_word_counter(doc=x, term_vector=h.terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
colnames(unseen_2) <- sapply(h.terms.v, function(x){paste(x, "h", sep="_")}, USE.NAMES=F) %>% as.vector
rownames(unseen_2) <- raw$id

M2 <- cbind(unseen_1, unseen_2) %>% as.matrix

sw.predictions <- predict(sw.model, M2)
sw.classes <- ifelse(sw.predictions >= 0.5, 1, 0)

sh.predictions <- predict(sh.model, M2)
sh.classes <- ifelse(sh.predictions >= 0.5, 1, 0)

bd.predictions <- predict(bd.model, M2)
bd.classes <- ifelse(bd.predictions >= 0.5, 1, 0)
#TODO: adjust thresholds based on false negative/positive etc tendency of each model

total_year <- raw %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% group_by(Date) %>% count()

ggplot(total_year, aes(x = Date, y = n)) + geom_bar(stat = "identity")

predict.df <- data.frame( id = raw$id, Date = raw$Date, badge = bd.classes, sword = sw.classes, shield = sh.classes) %>% filter(badge+sword+shield > 0)
predict.df %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% group_by(Date) %>% summarize(badge = sum(badge), sword = sum(sword), shield = sum(shield)) %>%
  inner_join(total_year, by="Date") %>% mutate(badge = badge/n, sword = sword/n, shield = shield/n) %>%
  tidyr::gather(key="catg", value="count", badge:shield) %>%
  ggplot(aes(x=Date, y=count, color=catg)) + geom_line(size=1) +
  scale_x_continuous(breaks=1998:2023) +
  labs(title="Ratio of type of article over time", x = "Year", y = "Ratio")

predict.df %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% group_by(Date) %>% summarize(badge = sum(badge), sword = sum(sword), shield = sum(shield)) %>%
  tidyr::gather(key="catg", value="count", badge:shield) %>%
  ggplot(aes(x=Date, y=count, fill=catg)) + geom_bar(stat="identity", position="stack") +
  scale_x_continuous(breaks=1998:2023) +
  labs(title="Number of articles over time", x = "Year", y = "Count")
