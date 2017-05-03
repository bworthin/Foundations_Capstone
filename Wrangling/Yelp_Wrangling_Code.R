#PART 1: Importing Yelp business file

library(readr)
library(jsonlite)
library(tibble)
library(tidyr)
library(dplyr)
library(stringr)

#streamin with handler function to bring in specified variables for businesses with >=100 reviews, 
#and category "Restaurant"; stream out result to temp file, then assign to 'business' object

con_in <- file("yelp_academic_dataset_business.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df %>%
    select(business_id, stars, review_count, categories) %>%
    filter(review_count >= 100, str_detect(categories, "Restaurants")) %>%
    stream_out(con_out, pagesize = 5000)
}, pagesize = 5000)
close(con_out)

business <- stream_in(file(tmp))

business_tbl <- as_data_frame(business)


#Remove categories variable, since we don't need it anymore; then rename stars to yelp_avg_rating
business_tbl_filt <- business_tbl %>%
  select(-categories) %>%
  rename(yelp_avg_rating = stars) 

#Write to new csv file
yelp_business_clean <- business_tbl_filt
write.table(yelp_business_clean, "~/Foundations_Capstone/Wrangling/yelp_business_clean.csv", row.names = FALSE, sep = ",")

   
#PART 2: Importing Yelp review file (threshold = 100 reviews) and combining with business info

#Load yelp_business_clean.csv into data frame 'business_clean_df';contains business_id, review_count, yelp_avg_rating
yelp_business_clean <- read_csv("~/Foundations_Capstone/Wrangling/yelp_business_clean.csv")

#Streamin review file with handler function - subset based on business_id values that match above 

con_in <- file("~/Foundations_Capstone/Wrangling/yelp_academic_dataset_review.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df[df$business_id %in% yelp_business_clean$business_id,]
  df <- df %>%
    select(business_id, review_id, user_id, stars, date, text) %>%
    stream_out(con_out, pagesize = 10000)
}, pagesize = 10000)
close(con_out)

review_clean <- stream_in(file(tmp))

#Rename variables for clarity
review_clean <- review_clean %>%
  rename(stars_given = stars, review_date = date, review_text = text) 

#Write review data to new csv file
yelp_review_clean <- review_clean
write.table(yelp_review_clean, "~/Foundations_Capstone/Wrangling/yelp_review_clean.csv", row.names = FALSE, sep = ",")

#PART 3: Combining business and review data
yelp_bus_rev_clean <- left_join(yelp_business_clean, yelp_review_clean, by = "business_id")

#remove review and business files from workspace to free up memory
rm(yelp_business_clean)
rm(yelp_review_clean)

#write combined business and review data frame to csv
write.table(yelp_bus_rev_clean, "~/Foundations_Capstone/Wrangling/yelp_bus_rev_clean.csv", row.names = FALSE, sep = ",")


#PART 4: Importing and cleaning User file 

#Stream in user data according to user id's in combined business/review data

con_in <- file("~/Foundations_Capstone/Wrangling/yelp_academic_dataset_user.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df[df$user_id %in% yelp_bus_rev_clean$user_id,]
  df <- df %>%
    select(-type) %>%
    stream_out(con_out, pagesize = 10000)
}, pagesize = 10000)
close(con_out)

user_clean <- stream_in(file(tmp))

#Remove yelp_bus_rev_clean from workspace to free up memory
rm(yelp_bus_rev_clean)

#Rename average_stars to average_stars_given_byuser
user_clean <- rename(user_clean, avg_stars_given_byuser = average_stars)

#replace "None" with NA in 'elite' variable and in 'friends' variable
user_clean$elite[str_detect(user_clean$elite, "None")] <- NA
user_clean$friends[str_detect(user_clean$friends, "None")] <- NA

#Create new variables 'years_elite' (number of years user had elite status), 'friends_count' (number
#of friends user has) by calculating length of list for each observation of those variables 
user_clean$years_elite <- ifelse(is.na(user_clean$elite), 0, sapply(user_clean$elite, length))
user_clean$friends_count <- ifelse(is.na(user_clean$friends), 0, sapply(user_clean$friends, length))

#remove nested variables 'elite' and 'friends' since we've extracted data we need from them 
user_clean <- user_clean %>%
  select(-elite, -friends)

#Create new variables 'all_votes_given_byuser' (sum of all votes given) and 'all_comps_rec_byuser' 
#(sum of all compliments received)
user_clean$all_comps_rec_byuser <- user_clean %>%
  select(compliment_hot:compliment_photos) %>%
  rowSums(na.rm = TRUE)

user_clean$all_votes_given_byuser <- user_clean %>%
  select(useful:cool) %>%
  rowSums(na.rm = TRUE)

#Create new variable 'years_yelping' (calculates how many years since user joined yelp)
user_clean$yelping_since <- as.Date(user_clean$yelping_since)
user_clean$years_yelping <- as.numeric(difftime(Sys.Date(), user_clean$yelping_since)/365.25)
 
#Write to new csv file
yelp_user_clean <- user_clean
write.table(yelp_user_clean, "~/Foundations_Capstone/Wrangling/yelp_user_clean.csv", row.names = FALSE, sep = ",")

#PART 5: Combining user data with business & review data

