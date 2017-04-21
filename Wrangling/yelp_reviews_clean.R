#Importing Yelp review file: threshold = 100 reviews
library(readr)
library(jsonlite)
library(tibble)
library(tidyr)
library(dplyr)


#load yelp_business_clean.csv into data frame 'business_details_df';contains business_id, review_count, yelp_avg_rating
business_details_df <- read_csv("~/Foundations_Capstone/Wrangling/yelp_business_clean.csv")

#streamin review file with handler function - select business_id and review_id, subset based on business_id values that match above 

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

#rename stars variable - stars_given
bus_rev_ids <- rename(bus_rev_ids, stars_given = stars) 

#write to new csv file
yelp_bus_rev_thresh100 <- bus_rev_ids
write.table(yelp_bus_rev_thresh100, "~/Foundations_Capstone/Wrangling/yelp_bus_rev_thresh100.csv", row.names = FALSE, sep = ",")

