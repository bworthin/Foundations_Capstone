#Importing Yelp business file

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
    stream_out(con_out, pagesize = 1000)
}, pagesize = 1000)
close(con_out)

business <- stream_in(file(tmp))

business_tbl <- as_data_frame(business)


#remove categories variable, since we don't need it anymore; then rename stars to yelp_avg_rating
business_tbl_filt <- business_tbl %>%
  select(-categories) %>%
  rename(yelp_avg_rating = stars) 

#write to new csv file (any reason to write as new json instead? simple format now)
yelp_business_clean <- business_tbl_filt
write.table(yelp_business_clean, "~/Foundations_Capstone/Wrangling/yelp_business_clean.csv", row.names = FALSE, sep = ",")

   

