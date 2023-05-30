library(dplyr)
library(tidyverse)
library(tidytext)
library(ggplot2)
library(forcats)

# df = readr::read_csv('c://Users//SKim.CSIS.000//Documents//nk-statements//nlpy//tokenout.csv')
# 
# catg_words <- df %>% unnest_tokens(word, TEXT) %>% count(CATEGORY, word, sort=TRUE)
# total_words <- catg_words %>% group_by(CATEGORY) %>% summarize(total = sum(n))
# catg_words <- left_join(catg_words, total_words)

df2 = readr::read_csv('c://Users//SKim.CSIS.000//Documents//nk-statements//nlpy//my_checkset.csv')

catg_words2 <- df2 %>% unnest_tokens(word, text) %>% count(category, word, sort=TRUE)
total_words2 <- catg_words2 %>% group_by(category) %>% summarize(total = sum(n))
catg_words2 <- left_join(catg_words2, total_words2)

catg_tf_idf <- catg_words2 %>% bind_tf_idf(word, category, n)

catg_tf_idf %>% group_by(category) %>% slice_max(tf_idf, n=15) %>% ungroup() %>%
    ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = category)) +
    geom_col(show.legend = FALSE) + facet_wrap(~category, ncol=2, scales='free') +
    labs(x = 'tf-idf', y = NULL)

df2$date = as.Date(df2$date, format="%m/%d/%Y")
ggplot(df2, aes(x=as.Date(date), fill=category)) + geom_histogram(alpha=0.33, position="identity") +
  scale_x_date(date_breaks = "year") +
  theme(axis.text.x=element_text(angle=60, hjust=1))
