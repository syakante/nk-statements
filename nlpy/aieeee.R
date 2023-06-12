library(dplyr)
library(tidyverse)
library(tidytext)
library(ggplot2)
library(forcats)
library(readxl)
library(stringi)

dir = getwd()
checkset <- read_excel(paste(dir,"//sampleset.xlsx", sep=""))
checkset <- checkset[!duplicated(checkset$id),]
tokenized <- read_excel(paste(dir,"//nlpy//fulloutput.xlsx", sep="")) %>% subset(id %in% checkset$id)
df2 <- merge(checkset, tokenized, by="id") %>% select(id, headline, text, Date, category) %>% filter(Date < "2023-04-01")

catg_words2 <- df2 %>% unnest_tokens(word, text) %>% count(category, word, sort=TRUE)
total_words2 <- catg_words2 %>% group_by(category) %>% summarize(total = sum(n))
catg_words2 <- left_join(catg_words2, total_words2)

## most common words
mytidy <- df2 %>% unnest_tokens(word, text) %>% group_by(word) %>% filter(n() > 10) %>% ungroup()
mytidy %>% count(category, word, sort=TRUE) %>% group_by(category) %>% top_n(20) %>% ungroup() %>%  ggplot(aes(reorder_within(word, n, category), n,
                                                                                                          fill = category)) +
  geom_col(alpha = 0.8, show.legend = FALSE) +
  scale_x_reordered() +
  coord_flip() +
  facet_wrap(~category, scales = "free") +
  scale_y_continuous(expand = c(0, 0))

## tf-idf
catg_tf_idf <- catg_words2 %>% bind_tf_idf(word, category, n)

catg_tf_idf %>% group_by(category) %>% slice_max(tf_idf, n=15) %>% ungroup() %>%
    ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = category)) +
    geom_col(show.legend = FALSE) + facet_wrap(~category, ncol=2, scales='free') +
    labs(x = 'tf-idf', y = NULL)

## some date eda

df2$Date = as.Date(df2$Date, format="%Y-%m-%d")
ggplot(df2, aes(x=as.Date(Date), fill=category)) + geom_histogram(alpha=1, position="stack") +
  scale_x_date(date_breaks = "year", date_labels = "%Y") +
  theme(axis.text.x=element_text(angle=60, hjust=1))

## ML I hope

library(rsample)
set.seed(0)
df2$category <- as.factor(df2$category)
data_split <- df2 %>% select(id) %>% initial_split()
train_data <- training(data_split)
test_data <- testing(data_split)

sparse_words <- mytidy %>% count(id, word) %>% cast_sparse(id, word, n)
#for some reason there's an article that gets dropped from mytidy?
dropped = setdiff(c(train_data$id, test_data$id), as.numeric(rownames(sparse_words)))
test_data = test_data[!test_data$id == dropped,]
#sparse_words <- cbind(sparse_words, as.numeric(format(df2$Date[!df2$id == dropped], "%Y")))
myrownames <- as.integer(rownames(sparse_words))
docs_joined <- tibble(id = myrownames) %>% left_join(df2 %>% select(id, category))

library(glmnet)
library(doMC)
registerDoMC(cores=8)
fit = cv.glmnet(x = sparse_words, y = docs_joined$category, family = "multinomial", parallel = TRUE, keep = TRUE)
predictions <- predict(fit, newx = sparse_words[as.character(test_data),], type="class", s = fit$lambda.min)
actual <- df2$category[which(df2$id %in% test_data)] #rownames and stuff should work out. I think.
sum(actual == as.factor(as.vector(predictions)))/length(test_data)
#accuracy w/out date was ~0.85, with date was ~0.82. heh...
#null model aka always predicting most common catg is ~0.43 accuracy
#idk what to do with this though
