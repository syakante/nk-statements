# package download -------
required_packages <- c("dplyr", "tidyverse", "stringi", "readxl")
for(i in required_packages) {
  if(!require(i, character.only = T)) {
    #  if package is not existing, install then load the package
    install.packages(i, dependencies = T, repos = "http://cran.us.r-project.org")
    require(i, character.only = T)
  }
}

### vv modify these accordingly vv
setwd("..")
dir = getwd()
input_file <- paste(dir,r("new-sampleset.xlsx"), sep="")
all_docs_file <- r("C:\Users\me\Downloads\kcna-full-plsbeutf8.xlsx") #<-- put directory of wherever all data is here
output_file <- paste(dir,r("/sentences.csv"), sep="")

sample.df <- read_excel("new-sampleset.xlsx") %>% mutate(category = str_trim(tolower(category)))
sentences.df <- read_excel("C:\\Users\\me\\Downloads\\sampleset_236statements.xlsx") %>% select(id, Evidence) %>% merge(., sample.df[c("id", "category")], by="id") %>% subset(category != "drop") %>% distinct
sentences.df$Evidence = sentences.df$Evidence %>% stri_replace_all(" ", regex="\\s+") %>% stri_replace_all(". ", fixed="...") %>% stri_replace_all(". ", fixed=".")
#add text col to sample
sample.df <- read_excel("C:\\Users\\me\\Downloads\\kcna-full-plsbeutf8.xlsx") %>% select(id, text) %>% subset(id %in% sample.df$id) %>% merge(sample.df, ., on="id")

punctregex = "[.．！？!?](?:\\s+)?(?![.．！？!?])"

splitsent.df <- sentences.df %>% mutate(Evidence = stri_replace_all(Evidence, "", fixed="(끝)")) %>% mutate(sentence = strsplit(Evidence, punctregex, perl=T)) %>% 
  unnest(sentence) %>% select(id, sentence) %>% mutate(sentence = str_trim(sentence)) %>% subset(str_length(sentence) > 1)
tmp = merge(splitsent.df, sample.df[c("id", "category", "date")], by="id", all=F) %>% distinct
#^ sentences we can assign to a category
#now get sentences that are of "drop" category

tmpclean <- function(s){
  ret <- s %>% stri_replace_all(" ", regex="\\s+") %>% stri_replace_all(". ", fixed="...") %>% stri_replace_all(". ", fixed=".")
  return(ret)
}

allsents.df <- sample.df %>% select(id, text) %>% mutate(text = stri_replace_all(text, "", fixed="(끝)")) %>% mutate(sentence = strsplit(text, punctregex, perl=T)) %>% 
  unnest(sentence) %>% select(id, sentence) %>% mutate(sentence = tmpclean(str_trim(sentence))) %>% subset(stri_length(sentence)> 1)

#originally I was going to do setdiff but it turns out it doesnt always match exact
#so do str find. I guess.
#what exactly am I doing here? It would be more efficient to group by id so I only search for sentence matches within article Im looking for
#but... whatever. I don't care right now. I already ran the function
get_drop_sentences <- function(allsent, keep){
  sum(vapply(keep, function(x){stri_detect(allsent, regex=x)}, logical(1)))
}
funvalue = dim(splitsent.df)[1]
tmp2 <- vapply(allsents.df$sentence, function(x){get_drop_sentences(allsent=x, keep=splitsent.df$sentence)}, numeric(1), USE.NAMES=F)
dropsentences.df <- allsents.df[(tmp2 == 0),]
#umm
selectedid = read_excel("selected-w-headline2.xlsx") %>% select(id)
dropsentences.df <- dropsentences.df %>% subset(id %in% selectedid$id)
#some of these "sentences" are just comma-delimited lists
dropsentences.df <- dropsentences.df %>% subset(stri_count(dropsentences.df$sentence, fixed=",") < 5)
#5 July: have 4386 drop sentences, 674 categorized sentences
#mmm trim to sentences within max length in useable sentences
dropsentences.df <- dropsentences.df %>% subset(stri_length(dropsentences.df$sentence) <= max(stri_length(splitsent.df$sentence)))
#get to 4379 sentences here. yahoo.
#length hist of splitsent and dropsentences are similar so thats good
#Um... for now let's start with a sample of purely dropped sentences
#and a sample of sentences from articles that were categorized but weren't used as evidence
#im using ~.25*min(category), in this case 172 sword, so 40 articles from purely dropped and 40 from categorized but non-evidence
set.seed(0)
non_evidence <- dropsentences.df %>% filter(id %in% sentences.df$id, stri_length(sentence) > 5)
nonevisample <- non_evidence[sample(nrow(non_evidence), size=40),]
dropId <- setdiff(dropsentences.df, non_evidence) %>% subset(stri_length(sentence) > 5)
dropsample <- dropId[sample(nrow(dropId), size=40),]
dropsentences2.df <- data.frame(rbind(nonevisample, dropsample), category="drop")
out <- tmp %>% select(id, sentence, category) %>% rbind(dropsentences2.df)
write_excel_csv(out, "sentences.csv")

#split sents for all 8k selected aieeeeee
selected.df <- read_excel("C:\\Users\\me\\Downloads\\kcna-full-plsbeutf8.xlsx") %>% select(id, text, Date) %>% subset(id %in% selectedid$id)
selected.sent.df <- selected.df %>% select(id, text) %>% mutate(text = stri_replace_all(text, "", fixed="(끝)")) %>% mutate(sentence = strsplit(text, punctregex, perl=T)) %>% 
  unnest(sentence) %>% select(id, sentence) %>% mutate(sentence = tmpclean(str_trim(sentence))) %>% subset(stri_length(sentence)> 1)
write_excel_csv(selected.sent.df, "selected-sent-raw.csv")
