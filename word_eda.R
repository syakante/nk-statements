library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(tidytext)
library(ggplot2)

set.seed(0)

dir = getwd()
raw <- read_excel(paste(dir,"//selected-w-headline.xlsx", sep=""))
raw <- raw %>% mutate(Date = as.numeric(format(as.Date(Date), "%Y")))

## with all words

doc_words <- raw %>% unnest_tokens(word, text) %>% count(Date, word, sort=T)

total_words <- doc_words %>% group_by(Date) %>% summarize(total = sum(n))

doc_words <- left_join(doc_words, total_words)

doc_tf_idf <- doc_words %>% bind_tf_idf(word, Date, n)

doc_tf_idf %>% group_by(Date) %>% slice_max(tf_idf, n=4) %>% ungroup() %>%
  ggplot(aes(tf_idf, fct_reorder(word, tf_idf))) +
  geom_col(show.legend=FALSE) +
  facet_wrap(~Date, ncol=4, scales="free") +
  labs(x = 'tf-idf', y = NULL)

#^ some possible data of interest: top tf-idf words per year

doc_tf_idf %>% group_by(Date) %>% slice_max(tf_idf, n=1) %>% ungroup() 

## with keywords
#normally i'd just filter words from the tidy but keywords include phrases (i.e. longer than unigram)

terms.v <- read.table("features2.txt", sep="\n") %>% getElement("V1")
feature.unigrams <- terms.v[stri_count(terms.v, regex="\\s") == 0]
feature.bigrams <- terms.v[stri_count(terms.v, regex="\\s") == 1]
feature.trigrams <- terms.v[stri_count(terms.v, regex="\\s") == 2]
feature.ngrams <-terms.v[stri_count(terms.v, regex="\\s") >= 3]

#bigrams without keyword stuff for now

bigrams <- raw %>% unnest_tokens(bigram, text, token = "ngrams", n = 2) %>% filter(!is.na(bigram) & !stri_detect(bigram, fixed="우리")) %>% group_by(Date) %>% count(bigram, sort=T)
bigrams %>% filter(stri_detect(bigram, regex="핵")) %>% head(20)

unigrams.keywords <- raw %>% unnest_tokens(word, text) %>% filter(word %in% feature.unigrams) %>% count(word, sort=T)
bigrams.keywords <- raw %>% unnest_tokens(bigram, text, token = "ngrams", n = 2) %>% filter(!is.na(bigram) & bigram %in% feature.bigrams) %>% count(bigram, sort=T)
