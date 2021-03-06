# ----------------------------------------------------------------------------
# purpose:  fit a linear regression model and deploy an Azure ML web service
# audience: you are expected to have some prior experience with R
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# NOTE: In order to run this script you'll need to have the an Azure ML
# workspace, with its workspace ID and key.
# For details about Azure ML, go to http://studio.azureml.net/
# ----------------------------------------------------------------------------
# Enter your Azure ML Studio workspace info here before continuing.
ws_id <- ""
auth_token <- ""

# ----------------------------------------------------------------------------
# load packages
# ----------------------------------------------------------------------------
(if (!require("AzureML")) install.packages("AzureML"))
library("AzureML") # load the package for deploying Azure ML web service
(if (!require("MASS")) install.packages("MASS"))
library("MASS") # to use the Boston dataset

# ----------------------------------------------------------------------------
# fit a model and check model performance
# ----------------------------------------------------------------------------

# fit a model using all variables except medv as predictors
lm1 <- lm(medv ~ ., data = Boston)

# check model performance
summary(lm1)

pred <- predict(lm1)
mae <- mean(abs(pred - Boston$medv))
rmse <- sqrt(mean((pred - Boston$medv) ^ 2))
rae <- mean(abs(pred - Boston$medv)) / mean(abs(Boston$medv - 
                                                    mean(Boston$medv)))
rse <- mean((pred - Boston$medv) ^ 2) / mean((Boston$medv - 
                                                  mean(Boston$medv)) ^ 2)

print(paste("Mean Absolute Error: ", 
            as.character(round(mae, digit = 6)), sep = ""))
print(paste("Root Mean Squared Error: ", 
            as.character(round(rmse, digit = 6)), sep = ""))
print(paste("Relative Absolute Error: ", 
            as.character(round(rae, digit = 6)), sep = ""))
print(paste("Relative Squared Error: ", 
            as.character(round(rse, digit = 6)), sep = ""))


# workspace information
ws <- workspace(
    id = ws_id,
    auth = auth_token)

# define predict function
mypredict <- function(newdata) {
    res <- predict(lm1, newdata)
    res
}

# test the prediction function
newdata <- Boston[1, 1:13]
print(mypredict(newdata))

# Publish the service
ep <- publishWebService(ws = ws, fun = mypredict, 
                        name = "HousePricePrediction", inputSchema = newdata)

# ----------------------------------------------------------------------------
# consume the web service
# ----------------------------------------------------------------------------
# consume web service - 1st approach
pred <- consume(ep, newdata)
pred

# consume web service - 2nd approach
# retrieve web service information for later use
service_id <- ep$WebServiceId
# define endpoint
ep_price_pred <- endpoints(ws, service_id)
# consume
consume(ep_price_pred, newdata)

# ----------------------------------------------------------------------------
# update a web service and then consume
# ----------------------------------------------------------------------------
# define function for testing purpose
mypredictnew <- function(newdata) {
    res <- predict(lm1, newdata) + 100
    res
}

# update service with the new function
ep_update <- updateWebService(
    ws = ws,
    fun = mypredictnew,
    inputSchema = newdata,
    serviceId = ep$WebServiceId)

# consume the updated web service
consume(ep_price_pred, newdata)
