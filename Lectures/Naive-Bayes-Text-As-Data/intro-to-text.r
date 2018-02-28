# WWS586a Machine Learning for Policy Analysis
# 02-28-18
# Professor L. Jason Anastasopoulos (ljanastas@princeton.edu)
# Introduction to Text Analysis
# Topics covered
# (1) Acquiring text data from APIs
# (2) Pre-processing text data
# (3) Term document matrix

install.packages("pacman")
library(pacman)

# This loads and installs the packages you need at once
pacman::p_load(tm,SnowballC,foreign,plyr,twitteR,slam)


## Accessing online corpora
library(tm)
install.packages("tm.corpus.Reuters21578", 
                 repos = "http://datacube.wu.ac.at")
library(tm.corpus.Reuters21578)
data(Reuters21578)

## Let's see what the Reuters corpus looks like

inspect(Reuters21578[1:2])

## If we want to access the article we have to use the $ operator
Reuters21578[[1]]$content

## Extracting tweets using twitteR

library(twitteR)

## Imput your information 
setup_twitter_oauth(
  consumer_key="mkz0izzVKDRzkrR4GoyN9FStT", 
  consumer_secret="4A1YGFEixYmyUNf2idYC33GKCuFoyJkyKpQVXIXCpDedZe0nOt", 
  access_token="18249358-xZGyGz8sWmQ9oJ1TBsLKEczwtO24aJ0Q4waDbjxAd", 
  access_secret="uqH7cC5BLS65iuAEPEv4TXEtUZvFD80wH03xkqiB7SP7Y")

searchTwitter("@BarackObama")[1:10]


## Let's do a quick search of tweets that mention @BarackObama

ObamaTweets = searchTwitter("#BarackObama",n=100)
ObamaTweets[[1]]

## Example 2: Tapping into APIs using "jsonlite" 
library(jsonlite)
#Bills with the term "refugee in them"
bills<-fromJSON("https://www.govtrack.us/api/v2/bill?q=refugee") 

# We can retrieve the title and other information about these bills here 
# I'm creating a data frame with the bill title, bill id, bill sponsor
# id and the bill sponsors gender

billtitles<-bills$objects$title
billtype<-bills$objects$bill_type
sponsorid<-bills$objects$sponsor
sponsiridgender<-bills$objects$sponsor$gender

refugeebilldat<-
  data.frame(billtitles,billtype,sponsorid,sponsiridgender)

refugeebilldat[1:2,1:2]



## Tokenization example: Tweets mentioning "@POTUS"

library(plyr)
# Search Tweets with "@POTUS" 
potustweets = searchTwitter("@POTUS",n=5)
# Extract ONLY TEXT from the tweets
potustweets = lapply(potustweets, function(t) t$getText())
# Emoji's screw up all of out functions so we have to make sure
# that everything is in UTF-8 encoding
for(i in 1:length(potustweets)){
  potustweets[[i]]<-iconv(potustweets[[i]], "ASCII", "UTF-8", sub="")
}
# We have to put all the tweets in lowercase at this stage
# b/c of a screwy problem w/ the "tm" package
potustweets = lapply(potustweets, tolower)
# Let's see the first two
potustweets[1:2]



## Tokenization example: Tweets mentioning "@POTUS"

library(tm)
potuscorpus<-Corpus(VectorSource(potustweets))
potuscorpus


## Formatting example: Tweets mentioning "@POTUS"

potuscorpus<-tm_map(potuscorpus,
removePunctuation)
potuscorpus<-tm_map(potuscorpus,
stripWhitespace)
# Did it work?
potuscorpus[[1]]$content
#vs
potustweets[[1]]

potuscorpus<-tm_map(potuscorpus,
removeNumbers)

potuscorpus[[1]]$content


## Stop word removal

potuscorpus<-tm_map(potuscorpus,
                    removeWords, stopwords("english"))

potuscorpus[[1]]$content

potustweets[[1]]


## Stemming

potuscorpus<-tm_map(potuscorpus, 
                    stemDocument,lazy = TRUE)

potuscorpus[[1]]$content

potustweets[[1]]




## Building a pipeline

text_cleaner<-function(corpus){
tempcorpus<-Corpus(VectorSource(corpus))
tempcorpus<-tm_map(tempcorpus,
removePunctuation)
tempcorpus<-tm_map(tempcorpus,
stripWhitespace)
tempcorpus<-tm_map(tempcorpus,
removeNumbers)
tempcorpus<-tm_map(tempcorpus,
removeWords, stopwords("english"))
tempcorpus<-tm_map(tempcorpus, 
stemDocument)
return(tempcorpus)
}

potuscorpus<-text_cleaner(potustweets)
 
potuscorpus[[1]]$content
potuscorpus[[2]]$content

# Constructing the document term matrix

dtm <- DocumentTermMatrix(potuscorpus)
inspect(dtm[1:5, 1:5])
potuscorpus[[2]]$content



