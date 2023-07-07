library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(ggplot2)
library(ggpattern)

dir = getwd()
##TODO: I just updated the unseen seentences categorized data spreadsheets so update read_excels here accordingly.

# unseen <- read_excel("unseen-sentences-tokenized.xlsx") %>% select(sentence)
# sampleset <- read_excel("sentences-tokenized.xlsx") %>% select(sentence)
# all.df <- rbind(unseen, sampleset)
# rm(unseen)
# rm(sampleset)
# all.df <- all.df %>% tidytext::unnest_tokens(word, sentence) %>% select(word) %>% distinct
# #all.df = all.df[-c(29285),] #lol
# #for posterity this is to remove the word "heading"
# #which idk is not being removed
# data.table::fwrite(all.df, "vocab.txt")

### idek whats happening with the vocab stuf...

pred.sword.df <- read_excel("nlpy//fasttext_files//unseen-predictions-sword.xlsx") %>% mutate(sent_len = stri_length(stri_replace_all(sentence, replacement="", regex="\\s+"))) %>%
  group_by(article_id, category) %>% mutate(s_len = sum(sent_len)) %>% slice(1) %>% select(article_id, category, s_len, Date)
#pred.sword.df %>% mutate(Date = as.numeric(format(as.Date(Date), "%Y"))) %>% ggplot(aes(x=Date, y=s_len, fill=category)) + geom_bar(stat="identity", position="stack")

pred.badge.df <- read_excel("nlpy//fasttext_files//unseen-predictions-badge.xlsx") %>% mutate(sent_len = stri_length(stri_replace_all(sentence, replacement="", regex="\\s+"))) %>%
  group_by(article_id, category) %>% mutate(s_len = sum(sent_len)) %>% slice(1) %>% select(article_id, category, s_len, Date)
#pred.badge.df %>% mutate(Date = as.numeric(format(as.Date(Date), "%Y"))) %>% ggplot(aes(x=Date, y=s_len, fill=category)) + geom_bar(stat="identity", position="stack")

pred.shield.df <- read_excel("nlpy//fasttext_files//unseen-predictions-shield.xlsx") %>% mutate(sent_len = stri_length(stri_replace_all(sentence, replacement="", regex="\\s+"))) %>%
  group_by(article_id, category) %>% mutate(s_len = sum(sent_len)) %>% slice(1) %>% select(article_id, category, s_len, Date)
#pred.shield.df %>% mutate(Date = as.numeric(format(as.Date(Date), "%Y"))) %>% ggplot(aes(x=Date, y=s_len, fill=category)) + geom_bar(stat="identity", position="stack")

sword.sent.v <- read_excel("nlpy//fasttext_files//unseen-predictions-sword.xlsx") %>% subset(category=="sword") %>% getElement("unseen_sent_id")
shield.sent.v <- read_excel("nlpy//fasttext_files//unseen-predictions-shield.xlsx") %>% subset(category=="shield") %>% getElement("unseen_sent_id")
badge.sent.v <- read_excel("nlpy//fasttext_files//unseen-predictions-badge.xlsx") %>% subset(category=="badge") %>% getElement("unseen_sent_id")

uncategorized.sentences <- read_excel("unseen-sentences-tokenized.xlsx") %>% getElement("unseen_sent_id") %>% setdiff(y=unique(c(sword.sent.v, shield.sent.v, badge.sent.v)))

#words per year that werent classified into any category
uncategorized.df <- read_excel("unseen-sentences-tokenized.xlsx") %>% subset(unseen_sent_id %in% uncategorized.sentences) %>% mutate(Date = as.numeric(format(as.Date(Date), "%Y"))) %>%
  mutate(sent_len = stri_length(stri_replace_all(sentence, replacement="", regex="\\s+"))) %>% group_by(Date) %>% mutate(total_words = sum(sent_len)) %>% slice(1) %>% select(Date, total_words)

all.df <- read_excel("unseen-sentences-tokenized.xlsx") %>% group_by(article_id) %>% mutate(a_len = sum(stri_length(stri_replace_all(sentence, replacement="", regex="\\s+")))) %>%
  slice(1) %>% select(article_id, a_len, Date)
all.df <- pred.sword.df %>% ungroup() %>% subset(category=="sword") %>% select(article_id, s_len) %>% rename(sword_words = s_len) %>% merge(x=all.df, y=., by="article_id", all.x=T)
all.df <- pred.badge.df %>% ungroup() %>% subset(category=="badge") %>% select(article_id, s_len) %>% rename(badge_words = s_len) %>% merge(x=all.df, y=., by="article_id", all.x=T)
all.df <- pred.shield.df %>% ungroup() %>% subset(category=="shield") %>% select(article_id, s_len) %>% rename(shield_words = s_len) %>% merge(x=all.df, y=., by="article_id", all.x=T)
all.df <- all.df %>% mutate_all(~replace(., is.na(.), 0)) 
#"words" being total sentence length
#...though this puts us in awkward situations where sum of sword+badge+shield can be > than total article length due to possible overlapping sentence classification
#...oh well....

year_labs = (1998:2023 %% 100 %% 100) %>% as.character %>% vapply(.,function(x){if(str_length(x) < 2) paste("'0", x, sep="",collapse="") else paste("'",x,sep="",collapse="")}, FUN.VALUE = character(1), USE.NAMES = F)
#year_labs2 = c(" ", " ", "2000", " ", " ", " ", " ", "2005", " ", " ", " ", " ", "2010", " ", " ", " ", " ", "2015", " ", " ", " ", " ", "2020", " ", " ", " ")

colors.v = c("#dcf2f2", "#a8a8a7", "#bf2517", "#2474a6") #[2:4] for omitting uncatg.
bw.v = c("white", "grey", "black", "white")
patterns.v = c("stripe", "none", "none", "none")

ratio.line.color <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% mutate(sword = sum(sword_words)/sum((a_len)), badge = sum(badge_words)/sum((a_len)), shield = sum((shield_words)/sum((a_len)))) %>% 
  tidyr::gather(key="catg", value="ratio", sword:shield) %>% 
  ggplot(aes(x=Date, y=ratio, color=catg)) + geom_line(linewidth=1.2) +
  scale_x_continuous(breaks=1998:2023, labels=year_labs2) +
  labs(title="Ratio of classified words over time",
       subtitle="Sum of classified sentences' lengths over total article length per year",
       x="Year", y="Ratio") +
  scale_color_manual(name="Category",
                     breaks = c("badge", "sword", "shield"),
                     values=c("#a8a8a7", "#bf2517", "#2474a6")) +
  theme_minimal() + theme(panel.grid.minor.x = element_blank())

with.uncatg <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sword_words), badge = sum(badge_words), shield = sum((shield_words))) %>%
  merge(uncategorized.df, on=Date) %>% rename(uncategorized = total_words) %>%
  tidyr::gather(key="catg", value="count", sword:uncategorized) %>% mutate(catg = reorder(catg, match(catg, c("uncategorized", "badge", "sword", "shield")))) %>%
  ggplot(aes(x=Date, y=count, fill=catg)) + geom_bar(stat="identity",position="stack") +
  scale_x_continuous(breaks=1998:2023, labels=year_labs2) +
  scale_fill_manual(name = "Category",
                    breaks = c("uncategorized", "badge","sword", "shield"),
                    values = c("#dcf2f2", "#a8a8a7", "#bf2517", "#2474a6" )) +
  scale_y_continuous(expand=c(0,0), labels=scales::label_comma()) +
  labs(x = "Year", y = "Words", title="Total words of statements per year, 1998 - May 2023") + 
  theme_minimal() + theme(panel.grid.major.x = element_blank(),
                          panel.grid.minor.x = element_blank(),
                          axis.ticks.x = element_line(),
                          axis.line = element_line(),
                          panel.grid.major.y = element_line(color="lightgrey", size=0.25))

catg.only.color <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sword_words), badge = sum(badge_words), shield = sum((shield_words))) %>%
  tidyr::gather(key="catg", value="count", sword:shield) %>% mutate(catg = reorder(catg, match(catg, c("badge", "sword", "shield")))) %>%
  ggplot(aes(x=Date, y=count, fill=catg)) + geom_bar(stat="identity",position="stack") +
  scale_x_continuous(breaks=1998:2023, labels=year_labs2) +
  scale_fill_manual(name = "Category",
                    breaks = c("badge","sword", "shield"),
                    values = c("#a8a8a7", "#bf2517", "#2474a6" )) +
  scale_y_continuous(expand=c(0,0), labels=scales::label_comma()) +
  labs(x = "Year", y = "Words", title="Total words of statements per year, 1998 - May 2023") + 
  theme_minimal() + theme(panel.grid.major.x = element_blank(),
                          panel.grid.minor.x = element_blank(),
                          axis.ticks.x = element_line(),
                          axis.line = element_line(),
                          panel.grid.major.y = element_line(color="lightgrey", size=0.25))

ratio.line.bw <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% mutate(sword = sum(sword_words)/sum((a_len)), badge = sum(badge_words)/sum((a_len)), shield = sum((shield_words)/sum((a_len)))) %>% 
  tidyr::gather(key="catg", value="ratio", sword:shield) %>% 
  ggplot(aes(x=Date, y=ratio, linetype=catg)) + geom_line(linewidth=0.9) +
  scale_x_continuous(breaks=1998:2023, labels=year_labs) +
  labs(title="Ratio of classified words over time, Feb 1998 - June 2023",
       subtitle="Sum of classified sentences' lengths over total article length per year",
       x="Year", y="Ratio") +
  scale_linetype_manual(name="Category",
                     breaks = c("badge", "sword", "shield"),
                     values = c("dotted", "solid", "dashed")) +
  scale_y_continuous(expand=c(0,0), limits=c(0, 0.45)) +
  theme_bw(base_size = 10) + theme(panel.grid.minor.x = element_blank(),
                     legend.position="bottom",
                     legend.text = element_text(size = 7),
                     legend.title = element_text(size = 8),
                     legend.key.size = unit(2, "lines"),
                     legend.margin= margin(c(-10, 0, 0, 0)),
                     axis.text = element_text(size=6),
                     axis.title=element_text(size=8),
                     plot.subtitle = element_text(size=8)) +
  guides(linetype=guide_legend(ncol=3))

ggsave(filename = "ratio-time-bw.png", ratio.line.bw, device=png, dpi="print", units="in", width=5, height=3.5)

#aiee ggpattern bricked

legend.v = c("Uncategorized", "Badge","Sword", "Shield")
library(magick)

with.uncatg.bw <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sword_words), badge = sum(badge_words), shield = sum((shield_words))) %>%
  merge(uncategorized.df, on=Date) %>% rename(uncategorized = total_words) %>%
  tidyr::gather(key="catg", value="count", sword:uncategorized) %>% mutate(catg = reorder(catg, match(catg, c("uncategorized", "badge", "sword", "shield")))) %>%
  ggplot(aes(x=Date, y=count,fill=catg, pattern=catg, pattern_type=catg, pattern_scale=catg)) + 
  geom_col_pattern(col="black", pattern_fill="black") +
  scale_x_continuous(breaks=1998:2023, labels=year_labs) +
  scale_fill_manual(name = "Category",
                    breaks = c("uncategorized", "badge","sword", "shield"),
                    values = c("white", "black", "white", "white"),
                    labels = legend.v) +
  scale_pattern_manual(name = "Category",
                       breaks = c("uncategorized", "badge","sword", "shield"),
                       values=c("uncategorized"="magick", "badge"="none", "sword" = "magick", "shield" = "none"),
                       labels = legend.v) +
  scale_pattern_type_manual(name = "Category",
                            breaks = c("uncategorized", "badge","sword", "shield"),
                            values=c(uncategorized="right45", badge="none", sword="crosshatch30", shield="none"),
                            labels = legend.v) +
  scale_pattern_scale_manual(name = "Category",
                               breaks = c("uncategorized", "badge","sword", "shield"),
                               values=c(uncategorized=2, badge=0, sword=0.5, shield=0),
                               labels = legend.v) +
  scale_y_continuous(expand=c(0,0), limits=c(0, 900000), labels=scales::label_comma()) +
  labs(x = "Year", y = "Words", title="Total words of statements per year, Feb 1998 - June 2023") + 
  theme_bw() + theme(panel.grid.major.x = element_blank(),
                          panel.grid.minor.x = element_blank(),
                          axis.ticks.x = element_line(),
                          axis.line = element_line(),
                          panel.grid.major.y = element_line(color="lightgrey", size=0.25),
                          plot.title = element_text(size=18))

legend.v = c("Badge","Sword", "Shield")
catg.only.bw <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sword_words), badge = sum(badge_words), shield = sum((shield_words))) %>%
  tidyr::gather(key="catg", value="count", sword:shield) %>% mutate(catg = reorder(catg, match(catg, c("badge", "sword", "shield")))) %>%
  ggplot(aes(x=Date, y=count,fill=catg, pattern=catg, pattern_type=catg, pattern_scale=catg)) + 
  geom_col_pattern(col="black", pattern_fill="black") +
  scale_x_continuous(breaks=1998:2023, labels=year_labs) +
  scale_fill_manual(name = "Category",
                    breaks = c("badge","sword", "shield"),
                    values = c("black", "white", "white"),
                    labels = legend.v) +
  scale_pattern_manual(name = "Category",
                       breaks = c("badge","sword", "shield"),
                       values=c("badge"="none", "sword" = "magick", "shield" = "none"),
                       labels = legend.v) +
  scale_pattern_type_manual(name = "Category",
                            breaks = c("badge","sword", "shield"),
                            values=c(badge="none", sword="crosshatch30", shield="none"),
                            labels = legend.v) +
  scale_pattern_scale_manual(name = "Category",
                             breaks = c("badge","sword", "shield"),
                             values=c(badge=0, sword=0.5, shield=0),
                             labels = legend.v) +
  scale_y_continuous(expand=c(0,0), labels=scales::label_comma()) +
  labs(x = "Year", y = "Words", title="Total words of statements per year, Feb 1998 - May 2023") + 
  theme_minimal() + theme(panel.grid.major.x = element_blank(),
                          panel.grid.minor.x = element_blank(),
                          axis.ticks.x = element_line(),
                          axis.line = element_line(),
                          plot.title = element_text(size=18),
                          panel.grid.major.y = element_line(color="lightgrey", size=0.25))
