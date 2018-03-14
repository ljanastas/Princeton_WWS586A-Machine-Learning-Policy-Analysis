library(pacman)

# This loads and installs the packages you need at once
pacman::p_load(tm,SnowballC,foreign,plyr,twitteR,slam,foreign,wordcloud,LiblineaR,e1071,caret)

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

tweets<-trumptweets$Text

newcorpus<-text_cleaner(tweets, rawtext = FALSE)

# Create a document term matrix
dtm = DocumentTermMatrix(newcorpus)
dtm = removeSparseTerms(dtm, 0.99) # Reduce sparsity


# Create TF-IDF
dtm<-DocumentTermMatrix(newcorpus, control = list(weighting = weightTfIdf))
dtm<-removeSparseTerms(dtm, 0.99)
dtm_mat<-as.matrix(dtm)

viraltweets<-ifelse(trumptweets$Retweets > 613, 1,0)
nonviraltweets<-ifelse(trumptweets$Retweets < 613, 1,0)

viral_indices <- which(viraltweets == 1)
nonviral_indices <- which(nonviraltweets == 1)

# Naive Bayes with tweets ##########

train=sample(1:dim(trumptweets)[1],
             dim(trumptweets)[1]*0.8)
dtm_mat<-as.matrix(dtm)
trainX = dtm_mat[train,]
testX = dtm_mat[-train,]
trainY = viraltweets[train]
testY = viraltweets[-train]

traindata<-data.frame(trainY,trainX)
testdata<-data.frame(factor(testY),testX)

trctrl <- trainControl(method = "repeatedcv", number = 10, repeats = 1)

set.seed(3333)

# Naive bayes

nb_fit <- train(factor(trainY) ~., data = traindata, 
                method = "naive_bayes",
                trControl=trctrl)

# What do our predictions look like?
predict(nb_fit$finalModel,testdata)

print(nb_fit)

# Now predict on the test set 
test_pred <- predict(nb_fit, newdata = testdata)

confusionMatrix(test_pred, factor(testY) )

# Naive bayes with laplace smoothing

grid <- data.frame(fL=c(0,0.5,1.0), usekernel = TRUE, adjust=c(0,0.5,1.0))

nb_fit <- train(factor(trainY) ~., data = traindata, 
                method = "naive_bayes",
                trControl=trctrl,tuneGrid = grid)

print(nb_fit)

plot(nb_fit)

# Now predict on the test set 
test_pred <- predict(nb_fit, newdata = testdata)

confusionMatrix(test_pred, factor(testY) )





