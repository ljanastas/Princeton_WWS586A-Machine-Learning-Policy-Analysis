require(glmnet)
# Boston Housing Data
data(BostonHousing)
dim(BostonHousing)
head(BostonHousing)

Boston<-data.frame(BostonHousing)

# Data = considering that we have a data frame named dataF, with its first column being the class
x <- as.matrix(Boston[,c(1:3,5:13)]) # Removes class
y <- as.double(as.matrix(Boston[,14])) # Only class

# Let's create a new variable in which the housing prices are 1/0 for high- or 
# low-priced neighborhoods
y<-ifelse(y > median(y), 1, 0)


# Ridge regression 

# Fitting the model (Ridge: Alpha = 0)
set.seed(999)
cv.ridge <- cv.glmnet(x, y, family='binomial', alpha=0, 
                      standardize=TRUE, type.measure='auc')

# Results
plot(cv.ridge)

plot(cv.ridge$glmnet.fit, xvar="lambda", label=TRUE)
cv.ridge$lambda.min
cv.ridge$lambda.1se
coef(cv.ridge, s=cv.ridge$lambda.min)


# Lasso Regression
# Fitting the model (Lasso: Alpha = 1)
set.seed(999)
cv.lasso <- cv.glmnet(x, y, family='binomial', alpha=1,
                      standardize=TRUE, type.measure='auc')

# Results
plot(cv.lasso)


plot(cv.lasso$glmnet.fit, xvar="lambda", label=TRUE)
cv.lasso$lambda.min
cv.lasso$lambda.1se
coef(cv.lasso, s=cv.lasso$lambda.min)
