library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(tidytext)
library(doMC)

registerDoMC(cores=8)

terms.v <- read.table("features2.txt", sep="\n") %>% getElement("V1")

#feat2.v <- read_excel("new-features-tokenized.xlsx") %>% getElement("term")
#terms.v <- unique(c(terms.v, feat2.v))
#data.table::fwrite(list(terms.v), "features2.txt")

doc_word_counter <- function(doc, term_vector){
  #in: single doc
  #out: vector of length unique(dict$terms) that counts which word appeared how many times
  return(vapply(term_vector, function(x){stri_count(doc, regex=x)}, numeric(1)))
}

dir = getwd()
raw <- read_excel(paste(dir,"//nlpy//fulloutput.xlsx", sep=""))

#raw$Date = as.Date(raw$Date)
funvalue = length(terms.v)
word_freq_matrix <- as.data.frame(t(vapply(raw$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
docKeywordCount <- apply(word_freq_matrix, 1, sum)
hasKeyword <- raw$id[docKeywordCount > 0]
keep <- subset(raw, id %in% hasKeyword)


### adding recent docs
newDocs <- read_excel("march-to-june-tokenized.xlsx")
newDocs <- newDocs[which(newDocs$link %in% setdiff(newDocs$link, keep$link)),]
word_freq_matrix2 <- as.data.frame(t(vapply(newDocs$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
docKeywordCount2 <- apply(word_freq_matrix2, 1, sum)
keep2 <- newDocs[docKeywordCount2 > 0,]
lastID = max(raw$id)
keep2$id = (lastID+1):(lastID+dim(keep2)[1])

keep <- keep %>% add_row(keep2)

#write
#im too lazy to install xlsx package or whatever so uh...
write_excel_csv(keep, "selected.csv")

#read
#keep <- read_csv("myarticleids.csv", col_names = F)
#colnames(keep) <- c("id")

library(ggplot2)
raw$Date = as.Date(raw$Date)
raw %>% right_join(., select(keep, id), by="id") %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% tibble %>% group_by(Date) %>% count() %>% 
  ggplot(aes(x = Date, y = n)) + geom_bar(stat = "identity") + scale_x_continuous(breaks = 1998:2023) + labs(y = "Count", x = "Year") + theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust=1))

raw %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% tibble %>% group_by(Date) %>% count() %>% 
  ggplot(aes(x = Date, y = n)) + geom_bar(stat = "identity") + scale_x_continuous(breaks = 1998:2023) + labs(y = "Count", x = "Year") + theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust=1))

checkset %>% mutate(date = as.numeric(format(date, "%Y"))) %>% tibble %>% group_by(date, category) %>% count() %>% 
  ggplot(aes(x = date, y = n, fill=category)) + geom_bar(stat = "identity") + scale_x_continuous(breaks = 1998:2023) + labs(y = "Count", x = "Year") + theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust=1))

### sampling

sampleset = read_excel("sampleset.xlsx")
selected = read_excel("selected-w-headlines.xlsx") %>% select("id", "Date")
# um... in current sampleset, there's four articles (1868, 15019, 15021, and 15022) that aren't in selected i.e. don't meet >1 keyword criteria
# but.... idc.....

set.seed(1)

#stratified sampling by year
yearSample <- selected %>% subset(!(id %in% sampleset$id)) %>% mutate(Date = format(as.Date(Date), "%Y")) %>% group_by(Date) %>% sample_n(3) %>% getElement("id")
data.table::fwrite(tibble(id = yearSample), "strat-year-sample.csv")

#I was going to stratified sample by category but thats not possible rn lol
