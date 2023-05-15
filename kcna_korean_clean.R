# 1. PACKAGE DOWNLOAD -------
required_packages <- c("tidyverse", "stringr", "dplyr")
for(i in required_packages) {
  if(!require(i, character.only = T)) {
    #  if package is not existing, install then load the package
    install.packages(i, dependencies = T, repos = "http://cran.us.r-project.org")
    # install.packages(i, dependencies = T, repos = "https://cran.stat.upd.edu.ph/")
    require(i, character.only = T)
  }
}

# 2. READ IN DATA FROM SCRAPE FILE -----
data_og <- read.csv("kcna-핵-042423.csv")

# keep articles with >5 mentions
data <- subset(data_og,str_count(text, '핵') >= 5)
data <- subset(data,str_count(text, '일본') < 3)
data <- train
# reformat date info
data[c('Year', 'MoDa')] <- str_split_fixed(data$Date, '-', 2)
data$Year <- as.numeric(data$Year)

# 3. DEFINING TERMS ------
sh_list <- c('우리의 생존',
             '대조선핵선제공격',
             '미국의 핵선제공격',
             '방패로',
             '우리에 대한 핵선제공격',
             '핵위협이 가증',
             '핵악몽',
             '미국의 핵전쟁도발',
             '미국의 핵전쟁도발책동',
             '외부의 핵위협',
             '평화수호',
             '정당방위',
             '반핵',
             '평화적핵',
             '핵선제공격대상으로',
             '핵전쟁위협',
             '침략정책',
             '북침핵전쟁연습',
             '핵전쟁발발',
             '핵위협공갈',
             '방위력',
             '불장난',
             '평화적환경',
             '자위적',
             '핵전쟁책동',
             '생존권',
             '평화보장',
             '위협당하고')
sh_weights <- c(2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
sw_list <- c('핵반격',
             '가해질것',
             '전쟁밖에',
             '핵에는 핵으로',
             '민족의 생명이',
             '핵전투',
             '핵타격무장',
             '핵공격태세',
             '핵선제타격권',
             '섬멸의 포문',
             '전멸',
             '종국적파멸',
             '핵공격능력',
             '핵무력강화',
             '경고',
             '전투태세',
             '핵보검',
             '전투준비태세',
             '조미핵대결전',
             '전쟁상태',
             '막을수 없다',
             '자멸',
             '교전관계',
             '보복타격',
             '주체무기',
             '위력한 보검',
             '장검',
             '정밀핵타격수단')
sw_weights <- c(2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
ba_list <- c('세계앞에서',
             '핵보유국의 전렬',
             '핵보유국지위',
             '핵강국의 전렬',
             '당당한 핵보유국',
             '최첨단핵',
             '세기적인 기적',
             '국가핵무력완성',
             '힘의 대결',
             '동방의 핵강국',
             '자랑스러운',
             '세상에 없다',
             '신뢰성',
             '세계적인 핵',
             '조미대결',
             '당황',
             '힘찬 진군',
             '공화국핵무력',
             '정의의 핵억제력',
             '천하무적의 핵강국',
             '힘의 대결',
             '대결시대',
             '전략적지위',
             '놀라',
             '우리 식의',
             '초강도',
             '더 위력한',
             '무진막강한')
ba_weights <- c(2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)

# combine lists + weights into one key
lists <- c(ba_list, sw_list, sh_list)
weights <- c(ba_weights, sw_weights, sh_weights)
df_key <- data.frame(lists, weights)

# pull articles from set that mention a keyword
df_use <- subset(data, grepl(paste(lists, collapse = "|"), text))

# 4. SCORING & CATEGORIZING -----

# scoring
list_use <- data.frame(ba_list, sw_list, sh_list)
for (i in 1:ncol(list_use)) { # for each category...
  df_use <- df_use %>%
    add_column(score = 0) # create a score column...
  for (j in 1:nrow(list_use)) { # for each term within the category...
    weight <- df_key %>% filter(lists == list_use[j,i]) %>% pull(weights)
    vec <- str_count(df_use$text, list_use[j,i]) * weight
    df_use[ncol(df_use)] <- df_use[ncol(df_use)] + vec # add weight to score if the term appears.
    print(list_use[j,i])
  }
}
#grepl(list_use[j,i], df_use$text)
# categorize
# basically, everything starts out as 'badge.' if other scores are higher, replace the category.
df_use <- df_use %>%
  add_column(degree = df_use$score) %>%
  add_column(category = 'BADGE') %>% 
  mutate(degree = ifelse(score.1 > degree, score.1, degree),
         category = ifelse(score.1 > score, 'SWORD', category)) %>% 
  mutate(category = ifelse(score.2 > degree, 'SHIELD', category),
         degree = ifelse(score.2 > degree, score.2, degree))
df_use <- df_use %>%
  mutate(category = ifelse(category == 'BADGE' & (degree == score.1 | degree == score.2), 'TIE', category)) %>%
  mutate(category = ifelse(category == 'SWORD' & (degree == score.2), 'TIE', category))

# create a simpler, final dataset.
df_final <- df_use[c("headline", "link", "text", "Date", "Year", "degree", "category")]
df_final <- df_final %>%
  add_column(length = str_length(df_final$text))
#write.csv(df_final, "kcna-pull.csv")

#lengths
hist(df_final$length.1, xlim = range(0,20000), breaks = 100)
#degrees
hist(df_final$degree, breaks = 50)

# 5. SUMMARIZE FOR VISUALIZATIONS -----
# uses categories (first graph)
df_summ <- data.frame(text = NA)[numeric(0), ]
categories <- c('BADGE', 'SHIELD', 'SWORD')
for (i in 1998 : 2023) {
  for (j in categories) {
    count <- sum(df_final$Year == i & df_final$category == j)
    dbind <- cbind(i, j, count)
    df_summ <- rbind(df_summ, dbind)
  }
}
df_summ_wide <- pivot_wider(as.data.frame(df_summ), names_from = j, values_from = count)
# open df_summ_wide and copy info to flourish

# uses scores (second graph)
df_summ <- data.frame(text = NA)[numeric(0), ]
categories <- c('BADGE', 'SWORD', 'SHIELD')
k = 7
for (i in 1998 : 2023) {
  for (j in categories) {
    count <- sum(df_use[which(df_use$Year == i), k])
    dbind <- cbind(i, j, count)
    df_summ <- rbind(df_summ, dbind)
    k = k+1
  }
  k = 7
}
df_summ_wide <- pivot_wider(as.data.frame(df_summ), names_from = j, values_from = count)

#6. MISCELLANOUS FUNCTIONS (IGNORE) -------

# thing for timeline -- number of terms per year
df_summ <- data.frame(text = NA)[numeric(0), ]
for (i in 1998 : 2023) {
  count <- sum(data$Year == i)
  dbind <- cbind(i, count)
  df_summ <- rbind(df_summ, dbind)
}

# thing for word cloud -- all words that contain 핵, remove endings
df_context <- data %>% 
  filter(Year == 2022) %>%
  mutate(context = str_extract_all(text, "\\b(?=\\p{L}*핵)\\p{L}+\\b")) %>%
  unnest(cols = c(context)) %>%
  select(context)
for (i in 1 : 59080) {
  if(str_sub(df_context$context[i], -1) %in% c('의', '에', '을', '은', '이', '를', '는', '과')) {
    df_context$context[i] <- str_sub(df_context$context[i], end = -2)
  }
}

# list of terms, how many results per each?
df_summ <- data.frame(text = NA)[numeric(0), ]
for (i in clist) {
  df_summ <- cbind(df_summ, nrow(subset(data, grepl(i, text))))
}