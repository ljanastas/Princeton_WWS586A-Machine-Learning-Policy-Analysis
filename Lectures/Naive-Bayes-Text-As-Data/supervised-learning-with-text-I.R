library(pacman)

# This loads and installs the packages you need at once
pacman::p_load(tm,SnowballC,foreign,plyr,twitteR,slam,foreign,wordcloud,LiblineaR,e1071,caret)

setwd("~/Dropbox/Princeton-Classes-Spring-2018/Applied Machine Learning/WWS586A-Machine-Learning-Policy-Analysis/Lectures/Naive-Bayes-Text-As-Data")
source("cleaner.r")

trumptweets <- read.csv("https://www.ocf.berkeley.edu/~janastas/trump-tweet-data.csv")

tweets<-trumptweets$Text

newcorpus<-text_cleaner(tweets, rawtext = FALSE)

# Create a document term matrix
dtm = DocumentTermMatrix(newcorpus)
dtm = removeSparseTerms(dtm, 0.99) # Reduce sparsity

# Create TF-IDF
dtm<-DocumentTermMatrix(newcorpus, control = list(weighting = weightTfIdf))
dtm<-removeSparseTerms(dtm, 0.99)

# Removes the documents with no terms in them
rowTotals<-rowSums(as.matrix(dtm))
dtm <- dtm[rowTotals> 0, ]  

dtm_mat<-as.matrix(dtm)

viraltweets<-ifelse(trumptweets$Retweets[rowTotals > 0] > 63, 1,0)

viral_indices <- which(viraltweets == 1)

# Naive Bayes with tweets ##########
indices<-1:dim(dtm_mat)[1]

train=sample(indices,
             dim(dtm_mat)[1]*0.8)
trainX = dtm_mat[train,]
testX = dtm_mat[-train,]
trainY = viraltweets[train]
testY = viraltweets[-train]

traindata<-data.frame(trainY,trainX)
testdata<-data.frame(testY,testX)

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

grid <- data.frame(fL=c(seq(0.1,2,by=0.2)), usekernel = TRUE,adjust=c(seq(0.1,2,by=0.2)))

nb_fit <- train(factor(trainY) ~., data = traindata, 
                method = "naive_bayes",
                trControl=trctrl,tuneGrid = grid)

print(nb_fit)

plot(nb_fit)

# Now predict on the test set 
test_pred <- predict(nb_fit, newdata = testdata)

confusionMatrix(test_pred, factor(testY) )





