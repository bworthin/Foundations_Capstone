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

   
#PART 2: Importing Yelp review file: threshold = 100 reviews

#Load yelp_business_clean.csv into data frame 'business_details_df';contains business_id, review_count, yelp_avg_rating
business_details_df <- read_csv("~/Foundations_Capstone/Wrangling/yelp_business_clean.csv")

#Streamin review file with handler function - select business_id and review_id, subset based on business_id values that match above 

con_in <- file("~/Foundations_Capstone/Wrangling/yelp_academic_dataset_review.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df[df$business_id %in% business_details_df$business_id,]
  df <- df %>%
    select(business_id, review_id, user_id, stars) %>%
    stream_out(con_out, pagesize = 10000)
}, pagesize = 10000)
close(con_out)

bus_rev_ids <- stream_in(file(tmp))

#Rename stars variable - stars_given
bus_rev_ids <- rename(bus_rev_ids, stars_given = stars) 

#Write to new csv file
yelp_bus_rev_thresh100 <- bus_rev_ids
write.table(yelp_bus_rev_thresh100, "~/Foundations_Capstone/Wrangling/yelp_bus_rev_thresh100.csv", row.names = FALSE, sep = ",")


