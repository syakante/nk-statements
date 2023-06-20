# note -- this takes a long time to run, would not recommend going from the beginning.
# i'll be uploading most recent datasets to the sharepoint!
# use the 'scrape update' code to add things to that dataset, don't start from scratch :)

# package download -------
required_packages <- c("rvest", "RSelenium", "tidyverse", "stringr", "dplyr")
for(i in required_packages) {
  if(!require(i, character.only = T)) {
    #  if package is not existing, install then load the package
    install.packages(i, dependencies = T, repos = "http://cran.us.r-project.org")
    # install.packages(i, dependencies = T, repos = "https://cran.stat.upd.edu.ph/")
    require(i, character.only = T)
  }
}

# binman::rm_platform("phantomjs")
# wdman::selenium(retcommand = TRUE)
#um... due to permissions idt this works on work computer, only personal

#NAVIGATE TO PAGE  ------
#url <- "https://kcnawatch.org/?s=%22핵%22&source=190036&start=01-01-1997&end=14-03-2023" # update date
url <- "https://kcnawatch.org/?s=%22핵%22&source=190036&start=01-03-2022&end=20-06-2023" # update date
driver <- rsDriver(browser = "firefox", 
                   chromever = NULL)
rd <- driver[["client"]]
rd$navigate(url)

loadmorebutton <- rd$findElement(using = 'css selector', "#more_results")
for (i in 1:800){ # make larger if necessary
  print(i)
  loadmorebutton$clickElement()
  Sys.sleep(2)
}

#GET INFO AND STUFF  ------
page_source<-rd$getPageSource()
content <- read_html(page_source[[1]])
link <- content %>% html_nodes("h4 a") %>% html_attr("href")
headline <- content %>% html_nodes("h4 a") %>% html_text()
date <- content %>% html_nodes("p span") %>% html_text()
df <- data.frame(headline = headline, date_published = date, link = link)
rd$close()

#GET TEXT NOW -------
data <- data.frame(text = NA)[numeric(0), ]
for(i in 1:14984){ # update with however many rows
  url2 = df$link[i]
  content = read_html(url2)
  text <- content %>% html_nodes("div.article-content") %>% html_text()
  dbind <- cbind(df[i,], text)
  data <- rbind(data, dbind)
  print(i)
}

# NOW TO CLEAN AND SAVE ...
# date formatting, make year a number
data <- read.csv("kcna-핵.csv")
data[c('MoDa', 'Year')] <- str_split_fixed(data$date_published, ', ', 2)
data$Year <- as.numeric(data$Year)

data[c('Date')] <- as.Date(data$date_published, "%b %d, %Y")
data <- data[-c(1, 6, 7)]
data <- data[-c(2)]

# remove line breaks, other characters
data$text <- str_trim(gsub("\r?\n|\r", " ", data$text), "left")
data$headline <- str_trim(gsub("\r?\n|\r|·", " ", data$headline), "left")
data$link <- gsub("\r?\n|\r", " ", data$link)

write.csv(data, "202203-2023-06.csv")
