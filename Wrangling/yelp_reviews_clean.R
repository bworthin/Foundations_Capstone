#Importing Yelp review file

library(jsonlite)
library(tibble)
library(tidyr)
library(dplyr)
library(stringr)

#load yelp_business_clean.csv into data frame 'business_details_df';contains business_id, review_count, yelp_avg_rating
business_details_df <- read_csv("~/Foundations_Capstone/Wrangling/yelp_business_clean.csv")

#streamin review file with handler function - select business_id and review_id, subset based on business_id values that match above 

con_in <- file("~/Foundations_Capstone/Wrangling/yelp_academic_dataset_review.json")
con_out <- file(tmp <-tempfile(), open = "wb")
stream_in(con_in, handler = function(df) {
  df <- df[df$business_id %in% business_details_df$business_id]
  df %>%
    select(business_id, review_id) %>%
    stream_out(con_out, pagesize = 10000)
}, pagesize = 10000)
close(con_out)

bus_rev_ids <- stream_in(file(tmp))

bus_rev_ids_tbl <- as_data_frame(bus_rev_ids)





#add review_id, user_id, and stars?



#write to new csv file (any reason to write as new json instead?)
yelp_?????_clean <- reviews_tbl
write.table(yelp_reviews_clean, "~/Foundations_Capstone/Wrangling/yelp_reviews_clean.csv", row.names = FALSE, sep = ",")

