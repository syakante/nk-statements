library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(ggplot2)
library(ggrepel)
library(tidytext)
library(forcats)
library(rsample)
library(glmnet)
library(doMC)

set.seed(0)

# raw <- read_excel('C://Users//SKim.CSIS.000//Documents//nk-statements//nlpy//fulloutput.xlsx')
# #extra column from pandas on the left but w/e
# #filter out some articles
#blank ones, too many mentions of (foreign country), not enough uses of 핵
# raw <- raw %>% subset(text != "[]") %>% subset(stri_count(text, regex="일본") < 3) %>% subset(stri_count(text, regex="핵") > 4)
# raw$Date <- as.Date(raw$Date, format="%Y-%m-%d")
# raw$id <- as.numeric(raw$id)

checkset <- read_excel("C://Users//SKim.CSIS.000//Documents//sampleset.xlsx")
checkset <- checkset[!duplicated(checkset$id),]
checkset$category <- as.factor(checkset$category)
tokenized <- read_excel('C://Users//SKim.CSIS.000//Documents//nk-statements//nlpy//fulloutput.xlsx') %>% subset(id %in% checkset$id) %>% select(id, text)
tokenized$id <- as.numeric(tokenized$id)

order <- match(checkset$id, tokenized$id)
tokenized <- tokenized[order,]
df <- merge(checkset, tokenized, by="id")

weights.df <- data.frame(
  term = c(c("우리 생존","대조선 핵선제공격","미국 핵선제공격","방패","우리 핵선제공격","핵위협 가증","핵악몽",
             "미국 핵전쟁 도발","미국 핵전쟁 도발 책동","외부 핵위협","평화 수호","정당방위","반핵","평화적핵",
             "핵선제공격 대상","핵전쟁 위협","침략 정책","북침 핵전쟁 연습","핵전쟁 발발","핵위협 공갈","방위력",
             "불장난","평화 환경","자위적","핵전쟁 책동","생존권","평화 보장","위협 당하","핵재난","전쟁광"),
           c("핵반격","전쟁 밖에","핵에는 핵으로","민족 생명","핵전투","핵타격 무장","핵공격 태세",
             "핵선제 타격 권","섬멸 포문","전멸","종국 파멸","핵공격 능력","핵무력 강화","경고","전투태세",
             "핵보검","전투준비태세","조미 핵대결 전","전쟁 상태","막을수 없","자멸","교전 관계","보복 타격",
             "주체 무기","위력한 보검","장검","정밀 핵타격 수단"),
           c("세계 앞","핵보유국 전렬","핵보유국 지위","핵강국 전렬","당당 핵보유국","최첨단핵","세기 기적",
             "국가 핵무력 완성","힘 대결","동방 핵강국","자랑 스럽","세상 없","신뢰성","세계 핵","조미 대결",
             "당황","힘찬 진군","공화국 핵무력","정의 핵억제력","기술 우세","힘 대결","대결 시대","전략 지위",
             "놀라","우리 식","초강도","더 위력한","무진 막강")),
  weight = c(rep(2, 12), rep(1, 18), rep(2, 11), rep(1, 16), rep(2, 12), rep(1, 16)),
  catg = c(rep("shield", 30), rep("sword", 27), rep("badge", 28))
)
#removed "가하", from sword

dict_count <- function(doc, c){
  #in: str doc, str which catg
  #out: int of counted weights for that category
  dict <- subset(weights.df, catg == c)
  twos <- subset(dict, weight == 2)$term
  ones <- subset(dict, weight == 1)$term
  tmp <- sum(vapply(X=twos, FUN=function(x){stri_count(doc, regex=x)}, FUN.VALUE=numeric(1)))
  return(sum(vapply(ones, function(x){stri_count(doc, regex=x)}, numeric(1))) + tmp)
  
}

catg_v <- c("shield", "sword", "badge")

doc_weight_counter <- function(doc){
  #in: single doc
  #out: vector of length three of shield/sword/badge counted weights
  return(vapply(catg_v, function(x){dict_count(doc, x)}, numeric(1)))
}

doc_word_counter <- function(doc){
  #in: single doc
  #out: vector of length unique(dict$terms) that counts which word appeared how many times
  return(vapply(weights.df$term, function(x){stri_count(doc, regex=x)}, numeric(1)))
}
ndocs <- dim(df)[1]
word_freq_matrix <- data.frame(matrix(rep(0, ndocs*85), nrow=ndocs, ncol=85))
word_freq_matrix <- as.data.frame(t(vapply(df$text, doc_word_counter, numeric(85), USE.NAMES = FALSE)))
colnames(word_freq_matrix) <- weights.df$term
word_freq_matrix$id = df$id
word_freq_matrix <- word_freq_matrix[, c(86, 1:85)]

wordMatrixCatg <- word_freq_matrix[,c(2:86)]
#wordMatrixCatg$category = df$category
rownames(wordMatrixCatg) <- df$id

docWordCount <- apply(word_freq_matrix[,-1], 1, sum)
# hasKeyword <- word_freq_matrix$id[which(docWordCount > 0)]
# idSample = sample(hasKeyword, 150, replace=F)
# totalWordFreq <- data.frame(term = weights.df$term, count = apply(word_freq_matrix[,2:86], 2, sum), row.names=NULL)

mytidy <- df %>% select(id, text) %>% unnest_tokens(word, text) %>% group_by(word) %>% filter(n() > 10) %>% ungroup()

data_split <- df %>% select(id) %>% initial_split()
train <- training(data_split) %>% getElement("id")
test <- testing(data_split) %>% getElement("id")

train.x <- wordMatrixCatg[as.character(train),]
train.y <- df[(df$id %in% train),] %>% getElement("category")

registerDoMC(cores=8)
fit = cv.glmnet(x = train.x, y = train.y, family = "multinomial", parallel = TRUE, keep = TRUE)
predictions <- predict(fit, newx = sparse_words[as.character(test_data),], type="class", s = fit$lambda.min)
actual <- df2$category[which(df2$id %in% test_data)] #rownames and stuff should work out. I think.
sum(actual == as.factor(as.vector(predictions)))/length(test_data)

