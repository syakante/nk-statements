library(dplyr)
library(tidyverse)
library(stringi)
library(readxl)
library(ggplot2)
library(ggpattern)

all.df <- read_excel("nlpy//fasttext_files//unseen-predictions.xlsx") %>% mutate(sent_len = stri_length(stri_replace_all(sentence, replacement="", regex="\\s+"))) %>% select(unseen_sent_id, article_id, Date, sw_category, sh_category, bd_category, sent_len)
uncategorized.df <- read_excel("unseen-sentences-tokenized.xlsx") %>% subset(unseen_sent_id %in% uncategorized.sentences) %>% mutate(Date = as.numeric(format(as.Date(Date), "%Y"))) %>%
  mutate(sent_len = stri_length(stri_replace_all(sentence, replacement="", regex="\\s+"))) %>% group_by(Date) %>% mutate(total_words = sum(sent_len)) %>% slice(1) %>% select(Date, total_words)


ratio.line.color <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sent_len * (sw_category == "sword"))/sum(sent_len), badge = sum(sent_len * (bd_category == "badge"))/sum(sent_len), shield = sum(sent_len * (sh_category == "shield"))/sum(sent_len)) %>% 
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

tmp <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sent_len * (sw_category == "sword")),
                                                                                                         badge = sum(sent_len * (bd_category == "badge")),
                                                                                                         shield = sum(sent_len * (sh_category == "shield")),
                                                                                                         uncategorized = sum(sent_len * (sw_category != "sword" & sh_category != "shield" & bd_category != "badge")))

with.uncatg <- all.df %>% mutate(Date = as.numeric(format(as.Date(Date),"%Y"))) %>% group_by(Date) %>% summarize(sword = sum(sent_len * (sw_category == "sword")),
                                                                                                                 badge = sum(sent_len * (bd_category == "badge")),
                                                                                                                 shield = sum(sent_len * (sh_category == "shield")),
                                                                                                                 uncategorized = sum(sent_len * (sw_category != "sword" & sh_category != "shield" & bd_category != "badge"))) %>%
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
