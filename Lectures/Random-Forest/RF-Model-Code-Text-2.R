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

# Create TF-IDF
dtm<-DocumentTermMatrix(newcorpus, control = list(weighting = weightTfIdf))
dtm<-removeSparseTerms(dtm, 0.99)
dtm_mat<-as.matrix(dtm)

viraltweets<-ifelse(trumptweets$Retweets > 63, 1,0)

viral_indices <- which(viraltweets == 1)


############ Training and testing ########################################

train=sample(1:dim(trumptweets)[1],
             dim(trumptweets)[1]*0.6)
dtm_mat<-as.matrix(dtm)
trainX = dtm_mat[train,]
testX = dtm_mat[-train,]
trainY = viraltweets[train]
testY = viraltweets[-train]

traindata<-data.frame(trainY,trainX)
testdata<-data.frame(factor(testY),testX)

############ Naive Bayes ########################################

trctrl <- trainControl(method = "repeatedcv", number = 10, repeats = 1)

set.seed(3333)

nb_fit <- train(factor(trainY) ~., data = traindata, 
                method = "naive_bayes",
                trControl=trctrl)

# Now predict on the test set 
test_pred <- predict(nb_fit, newdata = testdata)

confusionMatrix(test_pred, factor(testY) )


############ Random Forest with Caret ########################################
#Takes a very long time!
rf_fit <- train(factor(trainY) ~., data = traindata, 
                method = "rf", trControl=trctrl)

############ Random Forest with Ranger ########################################

rf_fit<-ranger(factor(trainY)~., data=traindata, 
                                 importance='impurity',
                                 write.forest=TRUE,
                                 probability=TRUE)


################################################################################################
################################################################################################
####### Draw the trees #########################################################################
################################################################################################
################################################################################################
################################################################################################

trees=rpart(factor(trainY)~., traindata)
plot(trees)
text(trees)

################################################################################################
################################################################################################
####### Performance######## ####################################################################
################################################################################################
################################################################################################
################################################################################################


# With ranger we have to generate the predicted probabilities and classify the tweets ourselves
rf_probs<-predict(rf_fit,data.frame(testdata))

rf_class<-ifelse(rf_probs$predictions[,2] > 0.5, 1,0)


# We can then manually assess performance 
confusion<-table(rf_class, testdata$factor.testY.)
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


################################################################################################
################################################################################################
####### Variable Importance ####################################################################
################################################################################################
################################################################################################
################################################################################################

# Let's extract the variable importance

varimp = rf_fit$variable.importance

# We can create a variable importance plot
# but it's a bit tricky

# Extract the words and their importance scores
words<-names(varimp)
importance<-as.vector(varimp)

# Create a data frame with both
importance.data = data.frame(words,importance)

# Now we need to reorder the data frame in descending order
# and only choose the top few words, let's say 20

importance.data = importance.data[order(-importance.data$importance),]
importance.data = importance.data[1:20,]

# Now we can use ggplot2 to create the plot
# Plot variable importance 
ggplot(importance.data, 
       aes(x=reorder(words,importance), y=importance,fill=importance))+ 
  geom_bar(stat="identity", position="dodge")+ coord_flip()+
  ylab("Variable Importance")+
  xlab("")+
  ggtitle("Word Importance Plot")+
  guides(fill=F)+
  scale_fill_gradient(low="red", high="blue")
















