# UPDATE THE DATABASE

# should start from whatever the last updated day was, scrape new articles
# delete all entries from prior set with date so there are no overlaps
# if port is already in use ... sudo lsof -nPi :yourPortNumber /// sudo kill -9 yourPIDnumber

key_date <- "13-03-2023"
existing_file <- "kcna-핵.csv"

#data <- data[-c(14985:15026),]
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

#NAVIGATE TO PAGE  ------
url <- paste0("https://kcnawatch.org/?s=%22핵%22&source=190036&start=", key_date, "&sort=recent")
driver <- rsDriver(browser = "firefox", 
                   chromever = NULL)
rd <- driver[["client"]]
rd$navigate(url)

loadmorebutton <- rd$findElement(using = 'css selector', "#more_results")
# this for loop clicks the "Load more" button n times
# it doesn't save the newly loaded articles, just loads the webpage so that the hyperlinks to older articles are available
# so if you want to go very far back you would have to click it a lot
for (i in 1:10){ 
  print(i)
  loadmorebutton$clickElement()
  Sys.sleep(2)
}
# loadmorebutton <- rd$findElement(using = 'css selector', "#more_results")
# while(!is.na(loadmorebutton)){
#   print("ok...")
#   loadmorebutton$clickElement()
#   loadmorebutton <- rd$findElement(using = 'css selector', "#more_results")
#   Sys.sleep(2)
# }


#GET INFO AND STUFF  ------
page_source<-rd$getPageSource()
content <- read_html(page_source[[1]])
link <- content %>% html_nodes("h4 a") %>% html_attr("href")
headline <- content %>% html_nodes("h4 a") %>% html_text()
date <- content %>% html_nodes("p span") %>% html_text()
df <- data.frame(headline = headline, date_published = date, link = link)
rd$close()

#GET TEXT NOW -------
newdata <- data.frame(text = NA)[numeric(0), ]
for(i in 1:dim(df)[1]){
  url2 = df$link[i]
  content = read_html(url2)
  text <- content %>% html_nodes("div.article-content") %>% html_text()
  dbind <- cbind(df[i,], text)
  newdata <- rbind(newdata, dbind)
  print(i)
}

# format for merge
newdata[c('Date')] <- format(as.Date(newdata$date_published, "%b %d, %Y"))
newdata <- newdata %>%
  select(headline, link, text, Date)

# remove line breaks, other characters
newdata$text <- str_trim(gsub("\r?\n|\r", " ", newdata$text), "left")
newdata$headline <- str_trim(gsub("\r?\n|\r|·", " ", newdata$headline), "left")
newdata$link <- gsub("\r?\n|\r", " ", newdata$link)

key_date <- paste0(substring(key_date, 7), substring(key_date, 3, 6), substring(key_date, 1, 2))

# MERGE SETS remove previous entries
data <- read.csv(existing_file)
data <- data %>%
  select(headline, link, text, Date) %>%
  filter(!Date == key_date) %>%
  rbind(newdata)

readr::write_excel_csv(newdata, "test.csv")
