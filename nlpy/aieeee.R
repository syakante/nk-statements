library(dplyr)
library(tidyverse)
library(tidytext)
library(ggplot2)
library(forcats)

df = readr::read_csv('c://Users//SKim.CSIS.000//Documents//nk-statements//nlpy//tokenout.csv')

catg_words <- df %>% unnest_tokens(word, TEXT) %>% count(CATEGORY, word, sort=TRUE)
total_words <- catg_words %>% group_by(CATEGORY) %>% summarize(total = sum(n))
catg_words <- left_join(catg_words, total_words)

df2 = readr::read_csv('c://Users//SKim.CSIS.000//Documents//nk-statements//nlpy//tokenoutkiwi.csv')

catg_words2 <- df2 %>% unnest_tokens(word, TEXT) %>% count(CATEGORY, word, sort=TRUE)
total_words2 <- catg_words2 %>% group_by(CATEGORY) %>% summarize(total = sum(n))
catg_words2 <- left_join(catg_words2, total_words2)

catg_tf_idf <- catg_words2 %>% bind_tf_idf(word, CATEGORY, n)

catg_tf_idf %>% group_by(CATEGORY) %>% slice_max(tf_idf, n=15) %>% ungroup() %>%
    ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = CATEGORY)) +
    geom_col(show.legend = FALSE) + facet_wrap(~CATEGORY, ncol=2, scales='free') +
    labs(x = 'tf-idf', y = NULL)
