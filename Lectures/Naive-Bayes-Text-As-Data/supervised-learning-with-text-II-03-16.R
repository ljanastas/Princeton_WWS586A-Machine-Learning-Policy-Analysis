## Supervised Learning with Text II: Naive Bayes and Support Vector Machines
## L. Jason Anastasopoulos (ljanastas@uga.edu)
## POLS 8500, Spring 2017
## University of Georgia

library(pacman)

# This loads and installs the packages you need at once
pacman::p_load(tm,SnowballC,foreign,plyr,twitteR,slam,foreign,wordcloud,LiblineaR,e1071, quanteda)

text_cleaner<-function(corpus, rawtext){
  tempcorpus = lapply(corpus,toString)
  for(i in 1:length(tempcorpus)){
    tempcorpus[[i]]<-iconv(tempcorpus[[i]], "ASCII", "UTF-8", sub="")
  }
  if(rawtext == TRUE){
    tempcorpus = lapply(tempcorpus, function(t) t$getText())
  }
  tempcorpus = lapply(tempcorpus, tolower)
  tempcorpus<-Corpus(VectorSource(tempcorpus))
  tempcorpus<-tm_map(tempcorpus,
                     removePunctuation)
  tempcorpus<-tm_map(tempcorpus,
                     removeNumbers)
  tempcorpus<-tm_map(tempcorpus,
                     removeWords, stopwords("english"))
  tempcorpus<-tm_map(tempcorpus, 
                     stemDocument)
  tempcorpus<-tm_map(tempcorpus,
                     stripWhitespace)
  return(tempcorpus)
}

trumptweets <- read.csv("https://www.ocf.berkeley.edu/~janastas/trump-tweet-data.csv")

trumptweets<-trumptweets[1:3917,]

tweets<-trumptweets$Text

newcorpus<-text_cleaner(tweets, rawtext = FALSE)

# Create a document term matrix
dtm <- DocumentTermMatrix(newcorpus)
dtm = removeSparseTerms(dtm, 0.99) # Reduce sparsity

dtm_mat<-as.matrix(dtm)

viraltweets<-ifelse(trumptweets$Retweets > 9366, 1,0)
nonviraltweets<-ifelse(trumptweets$Retweets < 3030, 1,0)

# Naive Bayes with text
# Split sample into training and test (75/25)
train=sample(1:dim(trumptweets)[1],
             dim(trumptweets)[1]*0.75)
dtm_mat<-as.matrix(dtm)
trainX = dtm_mat[train,]
testX = dtm_mat[-train,]
trainY = viraltweets[train]
testY = viraltweets[-train]

# Include only frequently used words
ten_words<-
  findFreqTerms(trainX,10)

ten_words[(length(ten_words)-20):length(ten_words)]

# Create DTM
fword_train <- 
  DocumentTermMatrix(newcorpus[train],
                     control=list(dictionary = ten_words))

fword_test <- 
  DocumentTermMatrix(newcorpus[-train],
                     control=list(dictionary = ten_words))


# Convert DTM to counts
counts <- function(x) {
  y <- ifelse(x > 0, 1,0)
  y <- factor(y, levels=c(0,1))
  y
}

fword_train <- apply(fword_train, 2, counts)
fword_test <- apply(fword_test, 2, counts)

# Training the model

viral_classifier <- 
  naiveBayes(x=fword_train,y=factor(trainY))

# Predict using test data

viral_test_pred <- 
  predict(viral_classifier, newdata=fword_test)

# Create the confusion matrix
confusion = table(testY,viral_test_pred)
confusion

# Accuracy
accuracy<-c(confusion[1,1]+confusion[2,2])/sum(confusion)
accuracy

# Specificity
specificity<-confusion[1,1]/sum(confusion[1,])
specificity

# Sensitivity
sensitivity<-confusion[2,2]/sum(confusion[2,])
sensitivity



