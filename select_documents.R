library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(tidytext)
library(doMC)

registerDoMC(cores=8)

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

doc_word_counter <- function(doc, term_vector){
  #in: single doc
  #out: vector of length unique(dict$terms) that counts which word appeared how many times
  return(vapply(term_vector, function(x){stri_count(doc, regex=x)}, numeric(1)))
}

dir = getwd()
raw <- read_excel(paste(dir,"//nlpy//fulloutput.xlsx", sep=""))
raw$Date = as.Date(raw$Date)
funvalue = length(terms.v)
word_freq_matrix <- as.data.frame(t(vapply(raw$text, function(x){doc_word_counter(doc=x, term_vector=terms.v)}, numeric(funvalue), USE.NAMES = FALSE)))
docKeywordCount <- apply(word_freq_matrix, 1, sum)
hasKeyword <- raw$id[docKeywordCount > 0]
keep <- subset(raw, id %in% hasKeyword)

data.table::fwrite(keep$id, "myarticleids.csv")

keep <- read_csv("myarticleids.csv", col_names = F)
colnames(keep) <- c("id")

library(ggplot2)
raw %>% right_join(., keep, by="id") %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% tibble %>% group_by(Date) %>% count() %>% 
  ggplot(aes(x = Date, y = n)) + geom_bar(stat = "identity") + scale_x_continuous(breaks = 1998:2023) + labs(y = "Count", x = "Year") + theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust=1))

raw %>% mutate(Date = as.numeric(format(Date, "%Y"))) %>% tibble %>% group_by(Date) %>% count() %>% 
  ggplot(aes(x = Date, y = n)) + geom_bar(stat = "identity") + scale_x_continuous(breaks = 1998:2023) + labs(y = "Count", x = "Year") + theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust=1))

checkset %>% mutate(date = as.numeric(format(date, "%Y"))) %>% tibble %>% group_by(date, category) %>% count() %>% 
  ggplot(aes(x = date, y = n, fill=category)) + geom_bar(stat = "identity") + scale_x_continuous(breaks = 1998:2023) + labs(y = "Count", x = "Year") + theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust=1))

###

sampleset = read_excel("sampleset.xlsx")
selected = read_excel("selected-w-headlines.xlsx") %>% select("id", "Date")
# um... in current sampleset, there's four articles (1868, 15019, 15021, and 15022) that aren't in selected i.e. don't meet >1 keyword criteria
# but.... idc.....

set.seed(1)

#stratified sampling by year
yearSample <- selected %>% subset(!(id %in% sampleset$id)) %>% mutate(Date = format(as.Date(Date), "%Y")) %>% group_by(Date) %>% sample_n(3) %>% getElement("id")
data.table::fwrite(tibble(id = yearSample), "strat-year-sample.csv")

#I was going to stratified sample by category but thats not possible rn lol