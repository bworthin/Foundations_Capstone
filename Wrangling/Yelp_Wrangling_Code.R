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

#Load yelp_business_clean.csv into data frame 'business_details_df';contains business_id, review_count, yelp_avg_rating
business_details_df <- read_csv("~/Foundations_Capstone/Wrangling/yelp_business_clean.csv")

#Streamin review file with handler function - subset based on business_id values that match above 

con_in <- file("~/Foundations_Capstone/Wrangling/yelp_academic_dataset_review.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df[df$business_id %in% business_details_df$business_id,]
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


#PART 4: Importing and cleaning User file 

#Load yelp_bus_rev.csv into data frame 'business_review_df';contains combined business and review info
business_review_df <- read_csv("~/Foundations_Capstone/Wrangling/yelp_bus_rev.csv")

#Stream in user data according to user id's in combined business/review data

con_in <- file("~/Foundations_Capstone/Wrangling/yelp_academic_dataset_user.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df[df$user_id %in% business_review_df$user_id,]
  df <- df %>%
    select(-type) %>%
    stream_out(con_out, pagesize = 10000)
}, pagesize = 10000)
close(con_out)

user_clean <- stream_in(file(tmp))

#Rename variables
#rename all votes columns with '_given_byuser' suffix

#rename all compliment variables with '_received_byuser' suffix

#rename average_stars to average_stars_given_byuser
user_clean <- rename(user_clean, avg_stars_given_byuser = average_stars)

#Create new variables 'total_votes_given_byuser' (count of all votes given) and 'total_comps_rec_byuser' 
#(count of all compliments received)

#Create new variables 'elite_years' (number of years user had elite status), 'friends_count' (number
#of friends user has)

#Create new variable 'yelping_since' (calculates how many years since user joined yelp)

#Write to new csv file
yelp_user_clean <- user_clean
write.table(yelp_user_clean, "~/Foundations_Capstone/Wrangling/yelp_user_clean.csv", row.names = FALSE, sep = ",")

#PART 5: Combining user data with business & review data

