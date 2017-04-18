#Importing Yelp business file

library(jsonlite)
library(tibble)
library(tidyr)
library(dplyr)
library(stringr)

business <- stream_in(file("yelp_academic_dataset_business.json"))
business_tbl <- as_data_frame(business)


#filter to businesses with >=100 reviews, with "Restaurants" as part of their category attribute
#remove unneeded columns/variables: hours, attributes, lat & long, neigh, address, open, type, categories
#rename starts column to 'yelp_avg_rating'
business_tbl_filt <- business_tbl %>%
  filter(review_count >= 100, str_detect(categories, "Restaurants")) %>%
  select(-starts_with("hours"), -starts_with("attributes"), -latitude, -longitude, 
             -neighborhood, -address, -is_open, -type, -categories) %>%
  rename(yelp_avg_rating = stars)
  
   

