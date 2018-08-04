######################################################################################################################
######################################################################################################################
#Table of content

#1 Spark
#1.1 Load libraries V
#1.2 Spark connection setup V
#1.3 Configuring connections V
#1.4 Data lakes 
#1.5 ML pipelines
#1.6 Production pipelines
#1.7 Distributed R 
#1.8 Reading/writing/creating Sparkdataframes
#1.9 Basic operations V
#1.10 Dplyer V
#1.11 SQL
#1.12 Machine learning
#1.13  Caching
#1.14 H20
#1.15 Graph analysis
#1.16 Text mining 


######################################################################################################################
######################################################################################################################
##1.1) Load libraries

set.seed(4444)

install.packages("")

library(sparklyr)
library(Rcpp)
library(rjson)
library(bit64)
library(sparklyr)
library(nycflights13)
library(Lahman)
library(dplyr)
library(DBI)
library(rsparkling)
library(dplyr)
library(h2o)
library(magrittr)
library(devtools)
######################################################################################################################
######################################################################################################################
##1.2) Spark connection setup


if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  Sys.setenv(SPARK_HOME = "C:/spark")
}
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "2g"))

sparkR.session()

#1sc2<-sparkR.session(master = "local[*]", sparkEnvir = list(spark.driver.memory = "2g"))

#  Checking the sparkR connection
df <- as.DataFrame(faithful)
# Displays the first part of the SparkDataFrame
head(df)

#2)Install a local version of Spark for development purposes
spark_install(version = "2.1.0")

#3)Upgrade to the latest version of sparklyr
devtools::install_github("rstudio/sparklyr")

#4)You can connect to both local instances of Spark as well as remote Spark clusters. 
#Here we'll connect to a local instance of Spark via the spark_connect function:
#You can connect to both local instances of Spark as well as remote Spark clusters. 
sc <- spark_connect(master = "local")

#sqlContext<-sparkR.session(sc)

#Checking the sparklyr sc connection
head(iris)
iris_tbl <- sdf_copy_to(sc = sc, x = iris, overwrite = T)
src_tbls(sc)
iris_tbl %>% count ## basci count for iris_tbl (i.e. iris SparkDataFrame)
head(iris_tbl) ## check the first a few rows of iris_tbl (i.e. iris SparkDataFrame)
######################################################################################################################
######################################################################################################################
##1.3) Configuring connections

# Configuration 1
conf <- spark_config()

conf$`sparklyr.cores.local` <- 4
conf$`sparklyr.shell.driver-memory` <- "16G"
conf$spark.memory.fraction <- 0.9

sc <- spark_connect(master = "local", 
                    version = "2.1.0",
                    config = conf)

## Check the connection (Version, storage memory and cores) ->  http://localhost:4041/storage -> Executers tab


#Configuration 2 - Dynamic allocation disabled
conf <- spark_config()

conf$`sparklyr.cores.local` <- 6
conf$`sparklyr.shell.driver-memory` <- "32G"
conf$spark.memory.fraction <- 0.9
conf$spark.dynamicAllocation.enabled <- "false"

sc <- spark_connect(master = "local", 
                    version = "2.1.0",
                    config = conf)

#Customizing connections
#A connection to Spark can be customized by setting the values of certain Spark properties. 
#In sparklyr, Spark properties can be set by using the config argument in the spark_connect() function.

#By default, spark_connect() uses spark_config() as the default configuration. 
#But that can be customized as shown in the example code below. Because of the unending number of 
#possible combinations, spark_config() contains only a basic configuration, so it will be very likely 
#that additional settings will be needed to properly connect to the cluster.
conf <- spark_config()   # Load variable with spark_config()

conf$spark.executor.memory <- "16G" # Use `$` to add or set values

sc <- spark_connect(master = "yarn-client", 
                    config = conf)  # Pass the conf variable 

## Check the connection (Version, storage memory and cores) ->  http://localhost:4041/storage -> Executers tab



# Local deployment
sparklyr::spark_install(version = "2.1.0")

sc <- spark_connect(master = "local")

######################################################################################################################
######################################################################################################################
##1.4) Reading/writing/creating Sparkdataframes

#1 Reading/writing data in CSV, JSON, and Parquet formats.
temp_csv <- tempfile(fileext = ".csv")
temp_parquet <- tempfile(fileext = ".parquet")
temp_json <- tempfile(fileext = ".json")

spark_write_csv(iris_tbl, temp_csv)
iris_csv_tbl <- spark_read_csv(sc, "iris_csv", temp_csv)

spark_write_parquet(iris_tbl, temp_parquet)
iris_parquet_tbl <- spark_read_parquet(sc, "iris_parquet", temp_parquet)

spark_write_json(iris_tbl, temp_json)
iris_json_tbl <- spark_read_json(sc, "iris_json", temp_json)

src_tbls(sc)


#2 Reading/writing data in CSV, JSON, and Parquet formats.
df <- as.DataFrame(faithful)
# Displays the first part of the SparkDataFrame
head(df)

#3 Reading in Jason file. 
#Note: Atypical jason file containting a separate, self-contained valid JSON object.  
people <- read.df("C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/people.json", "json")
head(people)

printSchema(people)

people <- read.json(c("C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/people.json", 
                      "C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/people2.json"))

head(people)

df <- read.df("C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/people.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")

head(df)

write.df(people, path = "C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/peopleparquet", source = "parquet")


#4 Creating SparkDataFrames from Hive tables. 
sparkR.session()

sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING)")
sql("LOAD DATA LOCAL INPATH 'C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/kv1.txt' INTO TABLE src")

# Queries can be expressed in HiveQL.
results <- sql("FROM src SELECT key, value")

# results is now a SparkDataFrame
head(results)

######################################################################################################################
######################################################################################################################
##1.5) Basic operations

#1 Functions
#Create the SparkDataFrame
df <- as.DataFrame(faithful)

# Get basic information about the SparkDataFrame
df

# Select only the "eruptions" column
head(select(df, df$eruptions))

# You can also pass in column name as strings
head(select(df, "eruptions"))

# Filter the SparkDataFrame to only retain rows with wait times shorter than 50 mins
head(filter(df, df$waiting < 50))


#2 Grouping/Aggregating
# We use the `n` operator to count the number of times each waiting time appears
head(summarize(groupBy(df, df$waiting), count = n(df$waiting)))

# We can also sort the output from the aggregation to get the most common waiting times
waiting_counts <- summarize(groupBy(df, df$waiting), count = n(df$waiting))
head(arrange(waiting_counts, desc(waiting_counts$count)))

#3 Operating on Columns
# Convert waiting time from hours to seconds.
# Note that we can assign this to a new column in the same SparkDataFrame
df$waiting_secs <- df$waiting * 60
head(df)

#4 Dapply collect
# Convert waiting time from hours to seconds.
# Note that we can apply UDF to DataFrame and return a R's data.frame
ldf <- dapplyCollect(
  df,
  function(x) {
    x <- cbind(x, "waiting_secs" = x$waiting * 60)
  })
head(ldf, 3)
######################################################################################################################
######################################################################################################################
##1.6) Dplyer

library(sparklyr)
library(dplyr)
library(nycflights13)
library(ggplot2)

sc <- spark_connect(master="local")
flights <- copy_to(sc, flights, "flights")
airlines <- copy_to(sc, airlines, "airlines")
src_tbls(sc)

select(flights, year:day, arr_delay, dep_delay)

filter(flights, dep_delay > 1000)

arrange(flights, desc(dep_delay))

summarise(flights, mean_dep_delay = mean(dep_delay,na.rm = TRUE))

mutate(flights, speed = distance / air_time * 60)

c1 <- filter(flights, day == 17, month == 5, carrier %in% c('UA', 'WN', 'AA', 'DL'))
c2 <- select(c1, year, month, day, carrier, dep_delay, air_time, distance)
c3 <- arrange(c2, year, month, day, carrier)
c4 <- mutate(c3, air_time_hours = air_time / 60)

c4


#Piping
c4 <- flights %>%
  filter(month == 5, day == 17, carrier %in% c('UA', 'WN', 'AA', 'DL')) %>%
  select(carrier, dep_delay, air_time, distance) %>%
  arrange(carrier) %>%
  mutate(air_time_hours = air_time / 60)


#Grouping
c4 %>%
  group_by(carrier) %>%
  summarize(count = n(), mean_dep_delay = mean(dep_delay,na.rm = TRUE))


#Collecting to R 
carrierhours <- collect(c4)

# Test the significance of pairwise differences and plot the results
with(carrierhours, pairwise.t.test(air_time, carrier))

ggplot(carrierhours, aes(carrier, air_time_hours)) + geom_boxplot()

#Dplyr sql
# Find the most and least delayed flight each day
bestworst <- flights %>%
  group_by(year, month, day) %>%
  select(dep_delay) %>% 
  filter(dep_delay == min(dep_delay,na.rm = TRUE) || dep_delay == max(dep_delay,na.rm = TRUE))
dbplyr::sql_render(bestworst)


bestworst

# Rank each flight within a daily
ranked <- flights %>%
  group_by(year, month, day) %>%
  select(dep_delay) %>% 
  mutate(rank = rank(desc(dep_delay)))
dbplyr::sql_render(ranked)


ranked

#Joining
flights %>% left_join(airlines)

flights %>% left_join(airlines, by = "carrier")

flights %>% left_join(airlines, by = c("carrier", "carrier"))

sample_n(flights, 10)

sample_frac(flights, 0.01)

#Dplyr hive functions
flights %>% 
  mutate(flight_date = paste(year,month,day,sep="-"),
         days_since = datediff(current_date(), flight_date)) %>%
  group_by(flight_date,days_since) %>%
  tally() %>%
  arrange(-days_since)
######################################################################################################################
######################################################################################################################
##1.7) SQL

if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  Sys.setenv(SPARK_HOME = "C:/spark")
}
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "2g"))

people <- read.df("C:/Users/giova/Desktop/Hoofdmap/Project 8 - Big-data demo/Superscripts/people.json", "json")

# Register this SparkDataFrame as a temporary view.
createOrReplaceTempView(people, "people")

# SQL statements can be run by using the sql method
Adults <- sql("SELECT name FROM people WHERE age >= 23 AND age <= 60")
head(Adults)
######################################################################################################################
######################################################################################################################
##1.8) Machine learning

####1.8.1Classification

# 1 Logistic regression
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/santanderCS.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")

training <- df
test <- df

head(df)

head (training)

# Fit an binomial logistic regression model with spark.logit
model <- spark.logit(training, TARGET ~ var38+var15+saldo_var30, maxIter = 10
#, regParam = 0.3, elasticNetParam = 0.8
)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)


# 2 Naive Bayes - Bernoulli
# Fit a Bernoulli naive Bayes model with spark.naiveBayes

nbModel <- spark.naiveBayes(df, TARGET ~ ind_var1_0 + ind_var1 + ind_var5_0)

# Model summary
summary(nbModel)

# Prediction
nbPredictions <- predict(df, test)
head(nbPredictions)




# 3 Support vector machines
# fit Linear SVM model
model <- spark.svmLinear(training,  TARGET ~ var38+var15+saldo_var30, regParam = 0.01, maxIter = 10)

# Model summary
summary(model)

# Prediction
prediction <- predict(model, training)
showDF(prediction)
head(prediction)




# 4 MLP
# specify layers for the neural network:
# input layer of size 4 (features), two intermediate of size 5 and 4
# and output of size 3 (classes)
layers = c(3,4,5)

# Fit a multi-layer perceptron neural network model with spark.mlp
model <- spark.mlp(training, TARGET ~ var38+var15+saldo_var30, maxIter = 100,
                   layers = layers, blockSize = 128, seed = 1234)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)









####1.8.2 Regression

# 1 Isotonic regression 
# Load training data
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/Isotonicdata.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
head(df)

training <- df
test <- df

# Fit an isotonic regression model with spark.isoreg
model <- spark.isoreg(training, Value ~ score, isotonic = FALSE)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)






# 2 Regression 
df <- read.df("C:/big-datademo/superscripts/R/data/FacebookPCI.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
head(df)

# Fit a generalized linear model of family "gaussian" with spark.glm
df_list <- randomSplit(df, c(2, 3), 1)
gaussianDF <- df_list[[1]]
gaussianTestDF <- df_list[[2]]
gaussianGLM <- spark.glm(gaussianDF, accuracy ~ x+y, family = "gaussian")

# Model summary
summary(gaussianGLM)

# Prediction
gaussianPredictions <- predict(gaussianGLM, gaussianTestDF)
head(gaussianPredictions)

# Fit a generalized linear model with glm (R-compliant)
gaussianGLM2 <- glm(accuracy ~ x+y, gaussianDF, family = "gaussian")
summary(gaussianGLM2)

# Fit a generalized linear model of family "binomial" with spark.glm
training2 <- read.df("C:/big-datademo/superscripts/R/data/multiclass-classificationdata.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
head(training2)
training2 <- transform(training2, label = cast(training2$Score > 1, "integer"))
df_list2 <- randomSplit(training2, c(7, 3), 2)
binomialDF <- df_list2[[1]]
binomialTestDF <- df_list2[[2]]
binomialGLM <- spark.glm(binomialDF, label ~ Feature1+Feature2, family = "binomial")

# Model summary
summary(binomialGLM)

# Prediction
binomialPredictions <- predict(binomialGLM, binomialTestDF)
head(binomialPredictions)



# Fit a generalized linear model of family "tweedie" with spark.glm
training3 <- read.df("C:/big-datademo/superscripts/R/data/multiclass-classificationdata.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
tweedieDF <- transform(training3, label = training3$Score * exp(randn(10)))
tweedieGLM <- spark.glm(tweedieDF, label ~ Feature1+Feature2, family = "tweedie",
                        var.power = 1.2, link.power = 0)

# Model summary
summary(tweedieGLM)



####1.8.2 Decision tree's
# 1 Decision tree regression
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/FacebookPCI.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
training <- df
test <- df
head(training)

# Fit a DecisionTree regression model with spark.decisionTree
model <- spark.decisionTree(training, accuracy ~ x+y+time+place_id, "regression")

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)


### 2 Decision tree classification
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/Outbrain_Y=Clicks.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
training <- df
test <- df
head(training)

# Fit a DecisionTree classification model with spark.decisionTree
model <- spark.decisionTree(training, clicked ~ display_id+ad_id, "classification")

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)



### 3 Random forest regression
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/FacebookPCI.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
training <- df
test <- df
head(training)
# Fit a random forest regression model with spark.randomForest
model <- spark.randomForest(training, accuracy ~ x+y+time, "regression", numTrees = 10)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)



### 4 Random forest classification
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/Outbrain_Y=Clicks.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
training <- df
test <- df
head(training)

# Fit a random forest classification model with spark.randomForest
model <- spark.randomForest(training, clicked ~ display_id+ad_id, "classification", numTrees = 10)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)




### 5 GBM regression

# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/FacebookPCI.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
training <- df
test <- df
head(training)
# Fit a GBT regression model with spark.gbt
model <- spark.gbt(training, accuracy ~ x+y+time+place_id, "regression", maxIter = 10)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)




### 6 GBM classification
# Load training data
df <- read.df("C:/big-datademo/superscripts/R/data/Outbrain_Y=Clicks.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
training <- df
test <- df
head(df)
# Fit a random forest classification model with spark.randomForest
model <- spark.randomForest(training, clicked ~ display_id+ad_id, "classification", numTrees = 10)

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)


### 1 K-means
df <- read.df("C:/big-datademo/superscripts/R/data/FacebookPCI.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
# Fit a k-means model with spark.kmeans
t <- as.data.frame(df )
head(t)
training <- createDataFrame(t)
df_list <- randomSplit(training, c(7,3), 2)
kmeansDF <- df_list[[1]]
kmeansTestDF <- df_list[[2]]
kmeansModel <- spark.kmeans(kmeansDF, ~ x + y + time + place_id,
                            k = 3)

# Model summary
summary(kmeansModel)

# Get fitted result from the k-means model
head(fitted(kmeansModel))

# Prediction
kmeansPredictions <- predict(kmeansModel, kmeansTestDF)
head(kmeansPredictions)




### 6 Collaborative filtering (ALS)
# Load training data
data <- list(list(0, 0, 4.0), list(0, 1, 2.0), list(1, 1, 3.0),
             list(1, 2, 4.0), list(2, 1, 1.0), list(2, 2, 5.0))
df <- createDataFrame(data, c("userId", "movieId", "rating"))
training <- df
test <- df
head(df)

# Fit a recommendation model using ALS with spark.als
model <- spark.als(training, maxIter = 5, regParam = 0.01, userCol = "userId",
                   itemCol = "movieId", ratingCol = "rating")

# Model summary
summary(model)

# Prediction
predictions <- predict(model, test)
head(predictions)




### 8 Frequent pattern mining
# Load training data

df <- selectExpr(createDataFrame(data.frame(rawItems = c(
  "1,2,5", "1,2,3,5", "1,2"
))), "split(rawItems, ',') AS items")
head(df)
fpm <- spark.fpGrowth(df, itemsCol="items", minSupport=0.5, minConfidence=0.6)

# Extracting frequent itemsets

spark.freqItemsets(fpm)

# Extracting association rules

spark.associationRules(fpm)

# Predict uses association rules to and combines possible consequents

predict(fpm, df)

