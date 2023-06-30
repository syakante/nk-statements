library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(tidytext)
library(doMC)

#registerDoMC(cores=8)

#feat2.v <- read_excel("new-features-tokenized.xlsx") %>% getElement("term")
#terms.v <- unique(c(terms.v, feat2.v))
#data.table::fwrite(list(terms.v), "features2.txt")
#terms.v <- read.table("features2.txt", sep="\n") %>% getElement("V1")

#previously used feature list to select documents, which are all selected by having mention of haek somewhere
#but presence of haek doesn't necessiate document being about nuclear
#neither does presense of some of these keywords, which can be very general
#so perhaps update document selection keyword criteria
#to having (haek prefix word, e.g. nuclear weapons, nuclear...)
#and maybe like some indicator of the DPRK referring to itself

regex.words <- read.table("features2.txt", sep="\n") %>% unnest_tokens(word, V1) %>% filter(stri_detect(word, regex="핵")) %>% getElement("word") %>% unique
regex.words <- regex.words[!regex.words == "핵"]
#our.words <- c("우리", "조선") #I think this should be enough. They refer to DPRK as "our republic" so "our" should cover it
#updated: new regex is (?<!남)조선(?!중앙통신)|우리
#because we don't care about articles that talk only about SK, and every article has 조선중앙통신 in it.
my.regex <- paste("^(?=.*(?:", paste(regex.words, sep="", collapse="|"), "))(?=.*(?:(?<!남)조선(?!중앙통신)|우리)).*$", sep="", collapse="")

dir = getwd()
raw <- read_excel(paste(dir,"//nlpy//fulloutput-headline.xlsx", sep=""))

selected <- raw %>% filter(stri_detect(text, regex=my.regex))

# #raw$Date = as.Date(raw$Date)
# funvalue = length(terms.v)
# word_freq_matrix <- as.data.frame(t(vapply(raw$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
# docKeywordCount <- apply(word_freq_matrix, 1, sum)
# hasKeyword <- raw$id[docKeywordCount > 0]
# keep <- subset(raw, id %in% hasKeyword)

#write
#im too lazy to install xlsx package or whatever so uh...
write_excel_csv(selected, "selected-w-headline2.csv")

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
