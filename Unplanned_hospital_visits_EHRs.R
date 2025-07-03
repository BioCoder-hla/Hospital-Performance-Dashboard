#################################################################
# PHASE 1, STEP 1.1: PROFESSIONAL DATA PREPROCESSING
# Objective: Transform raw hospital data into a clean, analysis-ready dataset.
#################################################################

# --- 1. SETUP ---
# install.packages("tidyverse")
# install.packages("janitor")
setwd("/home/wayne/Projects/Data Analytics/EHR_dash1")

# Load libraries
library(tidyverse)
library(janitor)
library(DBI)
library(RMySQL)

# --- 2. LOAD & CLEAN NAMES ---
# Load the raw data using read_csv for better performance and type inference
raw_df <- read.csv("Unplanned_Hospital_Visits-Hospital.csv")

# Use janitor to create clean, database-friendly column names
df <- clean_names(raw_df)

# --- 3. CORE TRANSFORMATION PIPELINE ---
processed_df <- df %>%
  mutate(
    # Convert key metric columns to numeric. as.numeric will smartly handle text like "Not Available" by converting it to NA.
    denominator = as.numeric(denominator),
    score = as.numeric(score),
    lower_estimate = as.numeric(lower_estimate),
    higher_estimate = as.numeric(higher_estimate),
    
    # Clean patient count columns by specifically replacing "Not Applicable" with NA, then converting to integer.
    number_of_patients = na_if(number_of_patients, "Not Applicable") %>% as.integer(),
    number_of_patients_returned = na_if(number_of_patients_returned, "Not Applicable") %>% as.integer(),
    
    # Parse character dates into proper R date objects using the mdy (month-day-year) function.
    start_date = mdy(start_date),
    end_date = mdy(end_date),
    
    # Preserve leading zeros in ZIP codes by converting to character and padding to 5 digits.
    zip_code = as.character(zip_code) %>% str_pad(width = 5, side = "left", pad = "0"),
    
    # Standardize the 'compared_to_national' column into a new, clean 'performance_category' column for easier analysis.
    performance_category = case_when(
      str_detect(compared_to_national, "No Different") ~ "Average",
      str_detect(compared_to_national, "Better") ~ "Better than National Average",
      str_detect(compared_to_national, "Worse") ~ "Worse than National Average",
      TRUE ~ NA_character_ # All other cases become NA
    )
  )
# Get a summary of the key numeric columns in your new data frame
summary(processed_df %>% select(score, denominator, number_of_patients))
# --- 4. VALIDATION ---
# Glimpse the final data structure to confirm all type conversions were successful.
print("--- Final Data Structure ---")
glimpse(processed_df)

# Check the new clean category
print("--- Cleaned Performance Categories ---")
print(table(processed_df$performance_category, useNA = "ifany"))

# Convert start_date to "day/month/year"
processed_df$start_date <- format(processed_df$start_date, "%d/%m/%Y")

# Convert end_date to "day/month/year"
processed_df$end_date <- format(processed_df$end_date, "%d/%m/%Y")

# --- 5. SAVE CLEAN DATA ---
# Export the fully processed data frame to a new CSV file.
write_csv(processed_df, "Unplanned_Visits_Cleaned.csv", na = "")

print("Preprocessing complete! 'Unplanned_Visits_Cleaned.csv' has been saved and is ready for database import.")




#################################################################
# PHASE 1, STEP 1.3: LOAD CLEANED DATA INTO MYSQL DATABASE
# Objective: Populate the 5 normalized tables from the clean CSV file.
#################################################################

# --- 1. SETUP: DATABASE CONNECTION ---

# --- !!! IMPORTANT: FILL IN YOUR DATABASE DETAILS HERE !!! ---
db_config <- list(
  host = "localhost",
  port = 3306,
  user = "root",
  password = "",  # Ensure this matches your XAMPP MySQL root password (likely empty)
  dbname = "hospital_performance",
  unix.socket = "/opt/lampp/var/mysql/mysql.sock"  # Updated socket path
)

con <- dbConnect(
  RMySQL::MySQL(),
  host = db_config$host,
  port = db_config$port,
  user = db_config$user,
  password = db_config$password,
  dbname = db_config$dbname,
  unix.socket = db_config$unix.socket
)

print("Successfully connected to the MySQL database.")


# --- 2. LOAD & PREPARE DATA ---

# Load the cleaned data you created in the previous step
full_data <- read.csv("Unplanned_Visits_Cleaned.csv")

# Load required package
library(dplyr)


# Step 1: Filter and aggregate data
performance_breakdown <- full_data %>%
  filter(!is.na(performance_category) & performance_category != "") %>%
  group_by(performance_category) %>%
  summarise(number_of_measures = n()) %>%
  mutate(total_measures = sum(number_of_measures),
         percentage = round((number_of_measures / total_measures) * 100, 1)) %>%
  arrange(desc(number_of_measures))

# Step 2: Display the results
print(performance_breakdown)

# Step 3: Replicate the tiering logic (assuming 3 tiers: better, average, worse)
num_categories <- nrow(performance_breakdown)
tier_size <- floor(num_categories / 3)

performance_breakdown <- performance_breakdown %>%
  mutate(chart_category = case_when(
    row_number() <= tier_size ~ "Better than National Average",
    row_number() <= 2 * tier_size ~ "National Average",
    TRUE ~ "Worse than National Average"
  ))

# Step 4: Compare with card output
# If you have the card's data (e.g., from API or manual extraction), compare here
# For example, if you extracted the chart data as a data frame 'card_data':
# card_data <- data.frame(
#   category = c("Better than National Average", "National Average", "Worse than National Average"),
#   measures = c(50, 30, 20),  # Replace with actual values from the chart
#   percentage = c(50.0, 30.0, 20.0)  # Replace with actual percentages
# )

# Compare
# comparison <- merge(performance_breakdown, card_data, by.x = "chart_category", by.y = "category", all = TRUE)
# print(comparison)

# Alternatively, manually inspect:
print("Calculated Breakdown:")
print(performance_breakdown[, c("chart_category", "number_of_measures", "percentage")])
# Compare with the chart's legend values (e.g., "Better than National Average (50 measures, 50.0%)")

# Step 5: Visualize to confirm (optional)
library(ggplot2)
ggplot(performance_breakdown, aes(x = "", y = number_of_measures, fill = chart_category)) +
  geom_bar(width = 1, stat = "identity") +
  coord_polar("y", start = 0) +
  labs(title = "National Performance Rating Validation", fill = "Category") +
  theme_minimal()# Add a unique row ID to the data frame. This will act as a temporary 'performance_id'
# before the database generates its own auto-incremented one.
full_data <- full_data %>% mutate(temp_id = row_number())


# --- 3. POPULATE DIMENSION TABLES ---
# This section extracts unique rows for hospitals, measures, and footnotes.

# 3.1 Populate 'hospitals' table
hospitals_df <- full_data %>%
  distinct(facility_id, .keep_all = TRUE) %>%
  select(facility_id, facility_name, address, city_town, state, zip_code, county_parish, telephone_number)

dbWriteTable(con, "hospitals", hospitals_df, append = TRUE, row.names = FALSE)
print(paste(nrow(hospitals_df), "unique hospitals loaded into the 'hospitals' table."))


# 3.2 Populate 'measures' table
measures_df <- full_data %>%
  distinct(measure_id, .keep_all = TRUE) %>%
  select(measure_id, measure_name)

dbWriteTable(con, "measures", measures_df, append = TRUE, row.names = FALSE)
print(paste(nrow(measures_df), "unique measures loaded into the 'measures' table."))


# 3.3 Populate 'footnotes' table
footnotes_df <- full_data %>%
  # Separate comma-delimited footnotes into individual rows
  separate_rows(footnote, sep = ", ") %>%
  # Filter out blank footnotes and get unique ones
  filter(footnote != "" & !is.na(footnote)) %>%
  distinct(footnote) %>%
  # Rename for the database table and ensure it's an integer
  transmute(footnote_id = as.integer(footnote),
            footnote_text = NA_character_) # We'll fill this in later if we find the crosswalk

# Note: We must handle potential duplicate footnote_ids before writing.
existing_footnotes <- dbGetQuery(con, "SELECT footnote_id FROM footnotes")
footnotes_to_write <- footnotes_df %>%
  anti_join(existing_footnotes, by = "footnote_id")

if(nrow(footnotes_to_write) > 0) {
  dbWriteTable(con, "footnotes", footnotes_to_write, append = TRUE, row.names = FALSE)
  print(paste(nrow(footnotes_to_write), "unique footnotes loaded into the 'footnotes' table."))
} else {
  print("Footnotes table already populated or no new footnotes to add.")
}


# --- 4. POPULATE THE FACT TABLE: 'performance_data' ---

performance_df <- full_data %>%
  select(
    facility_id, measure_id, denominator, score, lower_estimate,
    higher_estimate, number_of_patients, number_of_patients_returned,
    performance_category, start_date, end_date
  )

dbWriteTable(con, "performance_data", performance_df, append = TRUE, row.names = FALSE)
print(paste(nrow(performance_df), "records loaded into the 'performance_data' fact table."))


# --- 5. POPULATE THE JUNCTION TABLE: 'performance_footnotes' ---
# This is the most complex step.

# First, get the auto-incremented 'performance_id' from the database
# We assume the order is the same as we inserted. This is a reasonable assumption
# for a single-threaded script loading into an empty table.
performance_ids_from_db <- dbGetQuery(con, "SELECT performance_id FROM performance_data ORDER BY performance_id;")

# Combine the DB-generated IDs with our temporary IDs
# This gives us a map: temp_id -> performance_id
id_map <- tibble(
  temp_id = 1:nrow(performance_ids_from_db),
  performance_id = performance_ids_from_db$performance_id
)

# Now, create the data for the junction table
junction_df <- full_data %>%
  # Filter only rows that have footnotes
  filter(footnote != "" & !is.na(footnote)) %>%
  # Split comma-separated footnotes into separate rows
  separate_rows(footnote, sep = ", ") %>%
  # Join with our ID map to get the real performance_id
  left_join(id_map, by = "temp_id") %>%
  # Select the final columns and rename 'footnote' to 'footnote_id'
  transmute(
    performance_id = performance_id,
    footnote_id = as.integer(footnote)
  )

# Write the junction table data to the database
dbWriteTable(con, "performance_footnotes", junction_df, append = TRUE, row.names = FALSE)
print(paste(nrow(junction_df), "links loaded into the 'performance_footnotes' junction table."))


# --- 6. CLEANUP ---
dbDisconnect(con)
print("Data loading process complete. Database connection closed.")


