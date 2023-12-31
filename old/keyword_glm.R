library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(tidytext)
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

dir = getwd()
checkset <- read_excel(paste(dir,"//new-sampleset.xlsx", sep=""))
checkset <- checkset[!duplicated(checkset$id),]
checkset$category <- as.factor(checkset$category)
tokenized <- read_excel(paste(dir,"//nlpy//fulloutput-headline.xlsx", sep="")) %>% subset(id %in% checkset$id) %>% select(id, text)
tokenized$id <- as.numeric(tokenized$id)

order <- match(checkset$id, tokenized$id)
tokenized <- tokenized[order,]
df <- merge(checkset, tokenized, by="id")

# terms.df <- data.frame(
#   term = c(c("우리 생존","대조선 핵선제공격","미국 핵선제공격","방패","우리 핵선제공격","핵위협 가증","핵악몽",
#              "미국 핵전쟁 도발","미국 핵전쟁 도발 책동","외부 핵위협","평화 수호","정당방위","반핵","평화적핵",
#              "핵선제공격 대상","핵전쟁 위협","침략 정책","북침 핵전쟁 연습","핵전쟁 발발","핵위협 공갈","방위력",
#              "불장난","평화 환경","자위적","핵전쟁 책동","생존권","평화 보장","위협 당하","핵재난","전쟁광"),
#            c("핵반격","전쟁 밖에","핵에는 핵으로","민족 생명","핵전투","핵타격 무장","핵공격 태세",
#              "핵선제 타격 권","섬멸 포문","전멸","종국 파멸","핵공격 능력","핵무력 강화","경고","전투태세",
#              "핵보검","전투준비태세","조미 핵대결 전","전쟁 상태","막을수 없","자멸","교전 관계","보복 타격",
#              "주체 무기","위력한 보검","장검","정밀 핵타격 수단"),
#            c("세계 앞","핵보유국 전렬","핵보유국 지위","핵강국 전렬","당당 핵보유국","최첨단핵","세기 기적",
#              "국가 핵무력 완성","힘 대결","동방 핵강국","자랑 스럽","세상 없","신뢰성","세계 핵","조미 대결",
#              "당황","힘찬 진군","공화국 핵무력","정의 핵억제력","기술 우세","대결 시대","전략 지위",
#              "놀라","우리 식","초강도","더 위력한","무진 막강")),
#   catg = c(rep("shield", 30), rep("sword", 27), rep("badge", 27))
# )
#removed "가하", from sword
#"힘 대결" appeared twice in badge fsr

terms.v <- read.table("features2.txt", sep="\n") %>% getElement("V1")

doc_word_counter <- function(doc, term_vector){
  #in: single doc
  #out: vector of length unique(dict$terms) that counts which word appeared how many times
  return(vapply(term_vector, function(x){stri_count(doc, regex=x)}, numeric(1)))
}
ndocs <- dim(df)[1]
#get words with 핵 in them and count them
#how to handle dupes in old terms list..?
#answer: I decided I don't care.
haek.terms <- df %>% unnest_tokens(word, text) %>% filter(stri_detect(word, regex="핵")) %>% count(word, sort=T) %>% filter(n > 10) %>% getElement("word")
our.bigrams <- df %>% unnest_tokens(bigram, text, token="ngrams", n=2) %>% filter(!is.na(bigram), stri_detect(bigram, regex="^우리\\s")) %>% count(bigram, sort=T) %>% filter(n > 5) %>% getElement("bigram")
terms.v <- c(terms.df$term, haek.terms, our.bigrams)
funvalue = length(terms.v)
funvalue
word_freq_matrix <- data.frame(matrix(rep(0, ndocs*funvalue), nrow=ndocs, ncol=funvalue))
word_freq_matrix <- as.data.frame(t(vapply(df$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
colnames(word_freq_matrix) <- terms.v
#word_freq_matrix$id = df$id
rownames(word_freq_matrix) <- df$id
#word_freq_matrix <- word_freq_matrix[, c(85, 1:84)]

#wordMatrixCatg <- word_freq_matrix[,c(2:85)]
#wordMatrixCatg$category = df$category
#rownames(wordMatrixCatg) <- df$id

docWordCount <- apply(word_freq_matrix, 1, sum)
which(docWordCount==0)
df <- df[-which(docWordCount==0),]
#and then redo above operations. lol.

# hasKeyword <- word_freq_matrix$id[which(docWordCount > 0)]
# idSample = sample(hasKeyword, 150, replace=F)
# totalWordFreq <- data.frame(term = terms.df$term, count = apply(word_freq_matrix[,2:86], 2, sum), row.names=NULL)

#mytidy <- df %>% select(id, text) %>% unnest_tokens(word, text) %>% group_by(word) %>% filter(n() > 10) %>% ungroup()
# data_split <- df %>% filter(!id %in% names(which(docWordCount == 0))) %>% select(id) %>% initial_split()
data_split <- df %>% select(id) %>% initial_split()
train <- training(data_split) %>% getElement("id")
test <- testing(data_split) %>% getElement("id")


## glmnet with all words

sparse_words <- df %>% select(id, text) %>% unnest_tokens(word, text) %>% group_by(word) %>% filter(n() > 10) %>% ungroup() %>%
  count(id, word) %>%
  #filter(id %in% train) %>%
  cast_sparse(id, word, n)

#train.x <- word_freq_matrix[as.character(train),] %>% as.matrix %>% as("dgCMatrix")
train.x <- sparse_words[as.character(train),]
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% getElement("category")

#test.x <- word_freq_matrix[as.character(test),] %>% as.matrix %>% as("dgCMatrix")
test.x <- sparse_words[as.character(test),]
#tmp.m <- matrix(rep(0, length(test)*length(setdiff(colnames(train.x), colnames(test.x)))), nrow=length(test), ncol=length(setdiff(colnames(train.x), colnames(test.x))))
#colnames(tmp.m) <- setdiff(colnames(train.x), colnames(test.x))
#test.x <- cbind(test.x, tmp.m)
#test.x <- test.x[, colnames(train.x)]
test.y <- df %>% filter(id %in% test) %>% select(id, category)
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

registerDoMC(cores=8)
fit = cv.glmnet(x = train.x, y = train.y, family = "multinomial", parallel = TRUE, keep = TRUE)
predictions <- predict(fit, newx = test.x, type="class", s = fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#finding that I get like .9 training acc and then .6 test acc!! Aieeeee!!!!!


##Trying one-vs-rest instead...

#sword
data_split <- df %>% filter(!id %in% names(which(docWordCount == 0))) %>% select(id) %>% initial_split()
train <- training(data_split) %>% getElement("id")
test <- testing(data_split) %>% getElement("id")

train.x <- sparse_words[as.character(train),]
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% mutate(category = ifelse(category == "sword", "sword", "else")) %>% getElement("category")

test.x <- sparse_words[as.character(test),]
test.y <- df %>% filter(id %in% test) %>% select(id, category) %>% mutate(category = ifelse(category == "sword", "sword", "else"))
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

sword.fit <- cv.glmnet(x = train.x, y = train.y, family = "binomial", parallel = TRUE, keep = TRUE)

predictions <- predict(sword.fit, newx = test.x, type="class", s = fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#something like .84 train acc
#test acc is 2/3, only slightly better than null model :(

#shield
train.x <- sparse_words[as.character(train),]
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% mutate(category = ifelse(category == "shield", "shield", "else")) %>% getElement("category")

test.x <- sparse_words[as.character(test),]
test.y <- df %>% filter(id %in% test) %>% select(id, category) %>% mutate(category = ifelse(category == "shield", "shield", "else"))
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

shield.fit <- cv.glmnet(x = train.x, y = train.y, family = "binomial", parallel = TRUE, keep = TRUE)
predictions <- predict(shield.fit, newx = test.x, type="class", s = fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#.93 train acc
#got .74, not bad!! But could just be "lucky".
#null model is like .57

#badge
train.x <- sparse_words[as.character(train),]
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% mutate(category = ifelse(category == "badge", "badge", "else")) %>% getElement("category")

test.x <- sparse_words[as.character(test),]
test.y <- df %>% filter(id %in% test) %>% select(id, category) %>% mutate(category = ifelse(category == "badge", "badge", "else"))
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

badge.fit <- cv.glmnet(x = train.x, y = train.y, family = "binomial", parallel = TRUE, keep = TRUE)
predictions <- predict(badge.fit, newx = test.x, type="class", s = fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#.90 train acc
#.71 but null model is about .7 so not that good. aiee.

## one-vs-rest with selected keywords/bigrams. (I have no expectation to be any good given how all words models did but hmm ehh)
#sword
train.x <- word_freq_matrix[as.character(train),] %>% as.matrix %>% as("dgCMatrix")
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% mutate(category = ifelse(category == "sword", "sword", "else")) %>% getElement("category")

test.x <- word_freq_matrix[as.character(test),] %>% as.matrix %>% as("dgCMatrix")
test.y <- df %>% filter(id %in% test) %>% select(id, category) %>% mutate(category = ifelse(category == "sword", "sword", "else"))
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

sword.fit <- cv.glmnet(x = train.x, y = train.y, family = "binomial", parallel = TRUE, keep = TRUE)

predictions <- predict(sword.fit, newx = test.x, type="class", s = sword.fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#July 3:
#used latest features2.txt and latest training data from Ellen and Seihyeon
#got test of .88. Inch resting.
#But the predictions is just null model lol!
#also I was incorrectly using fit$lambda instead of sword.fit so

#shield
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% mutate(category = ifelse(category == "shield", "shield", "else")) %>% getElement("category")

test.y <- df %>% filter(id %in% test) %>% select(id, category) %>% mutate(category = ifelse(category == "shield", "shield", "else"))
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

shield.fit <- cv.glmnet(x = train.x, y = train.y, family = "binomial", parallel = TRUE, keep = TRUE)
predictions <- predict(shield.fit, newx = test.x, type="class", s = shield.fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#.69 test error which was... the same as the last time I used glmnet. Huh.

#badge
train.y <- df %>% filter(id %in% train) %>% select(id, category) #getElement("category")
order <- match(rownames(train.x), train.y$id)
train.y <- train.y[order,] %>% mutate(category = ifelse(category == "badge", "badge", "else")) %>% getElement("category")

test.y <- df %>% filter(id %in% test) %>% select(id, category) %>% mutate(category = ifelse(category == "badge", "badge", "else"))
order <- match(test, test.y$id)
test.y <- test.y[order,] %>% getElement("category")

badge.fit <- cv.glmnet(x = train.x, y = train.y, family = "binomial", parallel = TRUE, keep = TRUE)
predictions <- predict(badge.fit, newx = test.x, type="class", s = badge.fit$lambda.min)
sum(test.y == as.vector(predictions))/length(test.y)
#.71 test acc. Abt the same as last time. Huh...
#oh bc it's null modeling it. Wow.

#confusion matrix