# package download -------
required_packages <- c("tidyverse", "stringr", "dplyr")
for(i in required_packages) {
  if(!require(i, character.only = T)) {
    #  if package is not existing, install then load the package
    install.packages(i, dependencies = T, repos = "http://cran.us.r-project.org")
    # install.packages(i, dependencies = T, repos = "https://cran.stat.upd.edu.ph/")
    require(i, character.only = T)
  }
}
data <- read.csv("kcna-핵.csv")
data[c('Year', 'MoDa')] <- str_split_fixed(data$Date, '-', 2)
data$Year <- as.numeric(data$Year)

# NARROW TO DATASET #2 -----
list <- c("핵억제력",
          "핵무력",
          "핵시험",
          "비핵화",
          "핵문제",
          "핵무기",
          "핵전략")
data2 <- subset(data, grepl(paste(list, collapse = "|"), text))

train <- data[sample(nrow(data),25),]


# CHANGE VALUES HERE
clist <- c('남조선강점 미군', '미군이 철수하면', '미군이 남조선에서', 
           '미군 남조선강점', '미제침략군의 남조선강점')
clist <- c('조선반도의 비핵', '남조선에 핵무기', '남조선에 비핵')
clist <- c('세계 진보적인민들')
clist <- c('자주통일', '조국통일', '통일대강')


clist <- c('핵공격하기')
df_use2 <- subset(data, grepl(paste(clist, collapse = "|"), text))
write.csv(df_use2, "핵방패.csv")

#-----------------
# INDIVIDUAL TERMS DON'T MATTER, YEARS DO # i should mkae this for several terms
df_summ <- data.frame(text = NA)[numeric(0), ]
for (i in 1997 : 2023) {
  count <- sum(df_use2$Year == i)
  dbind <- cbind(i, count)
  df_summ <- rbind(df_summ, dbind)
}
df_summ_wide <- pivot_wider(as.data.frame(df_summ), names_from = j, values_from = count)

# LIST OF TERMS, HOW MANY RESULTS FOR EACH?
df_summ <- data.frame(text = NA)[numeric(0), ]
for (i in clist) {
  df_summ <- cbind(df_summ, nrow(subset(data, grepl(i, text))))
}

# EXTRACT TERMS AFTER TERM
df_context <- df_use %>%
  mutate(context = str_extract_all(text, "([^\\s]+\\s){1,3}적대시정책.?(\\s[^\\s]+){1,5}"))
# issue -- wont pull if the word is part of another word
# pull word first, then words after ?


df_use2 <- subset(data,str_count(text, '핵') >= 5)

# string.count(substring) -- number of mentions per term
for (i in sw_list) {
  df_use2 <- cbind(df_use2, as.integer(grepl(i, df_use2$text)))
  names(df_use2)[ncol(df_use2)] <- paste0(i)
  # could also pull the excerpt here
}

# MAKE SUMMARY TABLE
df_summ <- data.frame(text = NA)[numeric(0), ]
k <- 8
for (i in 1997 : 2023) {
  for (j in sw_list) {
    count <- sum(df_use2$Year == i & df_use2[k] == 1)
    dbind <- cbind(i, j, count)
    df_summ <- rbind(df_summ, dbind)
    k = k + 1
  }
  k = 8
}
#write.csv(df_summ, "kcna-pull.csv")

df_summ_wide <- pivot_wider(as.data.frame(df_summ), names_from = j, values_from = count)
#write.csv(df_summ_wide, "kcna-pull.csv")
# could even make a column that pulls text around term -- if only 1 match

mapply(sum, lapply(df_summ_wide, as.numeric))
