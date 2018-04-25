#### Task: categorize reviews by Movie Genre


library(pacman)

# This loads and installs the packages you need at once
pacman::p_load(tm,SnowballC,foreign,plyr,
               slam,foreign,
               caret,readr,dplyr,tidyr,topicmodels)

# Load the movie reviews data
movies<-read.csv("http://www.ocf.berkeley.edu/~janastas/data/movie-pang02.csv")

# Let's get the reviews themselves
review.text = movies$text

# Since this is a rather large sample and LDA is slow, let's take a random sample of 10% of the reviews
review.text = sample(review.text, length(review.text)*0.10)

# The first thing that we have to do is clean the data
# Stemming is highly recommended for this data
text_cleaner<-function(corpus){
  tempcorpus = lapply(corpus,toString)
  for(i in 1:length(tempcorpus)){
    tempcorpus[[i]]<-iconv(tempcorpus[[i]], "ASCII", "UTF-8", sub="")
  }
  tempcorpus = lapply(tempcorpus, tolower)
  tempcorpus<-Corpus(VectorSource(tempcorpus))
  toSpace <- content_transformer(function (x , pattern ) gsub(pattern, "", x))
  
  #Removing all the special charecters and words
  tempcorpus <- tm_map(tempcorpus, toSpace, "$")
  tempcorpus <- tm_map(tempcorpus, toSpace, "+")
  tempcorpus <- tm_map(tempcorpus, toSpace, "&")
  tempcorpus <- tm_map(tempcorpus, toSpace, "film")
  tempcorpus <- tm_map(tempcorpus, toSpace, "movie")
  tempcorpus <- tm_map(tempcorpus, toSpace, "one")
  tempcorpus <- tm_map(tempcorpus, removeNumbers)
  # Remove english common stopwords
  tempcorpus <- tm_map(tempcorpus, removeWords, stopwords("english"))
  # Remove punctuation
  tempcorpus <- tm_map(tempcorpus, removePunctuation)
  
  # Eliminate extra white spaces
  tempcorpus <- tm_map(tempcorpus, stripWhitespace)
  # Stem the document
  #tempcorpus <- tm_map(tempcorpus, PlainTextDocument)
  tempcorpus <- tm_map(tempcorpus,  stemDocument, "english")
  return(tempcorpus)
}

# Let's clean the reviews

cleanreviews = text_cleaner(review.text)

dtm = DocumentTermMatrix(cleanreviews)

dtmtopic <- dtm[rowSums(as.matrix(dtm))> 0, ]

dtm_topic<-as.matrix(dtmtopic)

# We should also create a vector which has the original reviews for us to inspect later

textreference<-review.text[rowSums(as.matrix(dtm))> 0]

# Using the topicmodels package, let's see if the model can recover something 
# close/similar to the 11 movie genres: 
# action, adventure, comedy, crime, drama, epic, horror
# musical, science fiction, war, westerns

set.seed(100)
ap_lda11 <- LDA(dtm_topic, k = 11, method="Gibbs")

# Let's see what our topics are comprised of

terms(ap_lda2, k=10)


# Let's do posterior inference this allows us to extract the distribution over terms, and the distribution over
# topics for each document

posterior_inference <- posterior(ap_lda11)

posterior_term_dist <- posterior_inference$terms
posterior_topic_dist<-posterior_inference$topics # This is the distribution of topics for each document

# posterior_term_dist contains the distribution over terms
dim(posterior_term_dist)
posterior_term_dist[1:5,1:5]

# posterior_topic_dist contains the distribution over topics
dim(posterior_topic_dist)
posterior_topic_dist[1:5,1:6]

# Let's focus on some of our clearest topics: Topic 4 which appears to be about "comedy" and
# topic 6 which appears to be about war.

# The first thing we need to do is to do is classify each review into its associated 
# topic by taking the maximum probability along each row of the  posterior_topic_dist matrix

# Which topic?
maxtopic<-c()

for(i in 1:dim(posterior_topic_dist)[1]){
  label = as.vector(which(posterior_topic_dist[i,] == max(posterior_topic_dist[i,])))[1]
  maxtopic[i]<-label
}

# This categorizes each of the reviews into a topic, let's take a look at the distribution of
# reviews
table(maxtopic)

# We have about 12 comedy reviews (topic 4) and 6 war reviews. Let's take a look 
# at the topic distributions of a comedy and war review

comedy.index = which(maxtopic == 4)
war.index = which(maxtopic == 6)

par(mfrow=c(1,2))
hist(posterior_topic_dist[comedy.index[1],], main = "Comedy Topic Distribution")

hist(posterior_topic_dist[war.index[1],], main = "War Topic Distribution")


# Now let's do some validation to ensure that these topics are correct.
# We are going to sample a review from each topic and take a quick look at them

sample.comedy = toString(textreference[comedy.index[1]])

sample.war = toString(textreference[war.index[1]])





