# Veridion – POC: Entity Resolution (R)

This repository contains the R script and resulting files created for the Veridion data-matching challenge.

The goal was to identify, for each input company, the most relevant candidate from several possible matches.  
The logic is fully rule-based and designed to be simple, clear, and reproducible.  
All steps were implemented in R using functions from the tidyverse package.

---

## Overview

Each input company has a few candidate records suggested by the system.  
The script compares these candidates, ranks them, and keeps only one—the best match for each input company.  
The results are then split into two groups:

- **APPROVED.csv** – automatically accepted matches  
- **DE_REVIZUIT_MANUAL.csv** – cases where the confidence is lower and should be reviewed manually

---

## Logic and steps

### Step 1 – Load and prepare data
- The dataset (CSV) is loaded and renamed to `date_curate` for easier reference.  
- Missing values in the `input_row_key` column are filled downward so that all candidate rows are correctly grouped.

### Step 2 – Create matching rules
1. **Exact name match**  
   Compares the lowercase version of `input_company_name` with  
   `company_name`, `company_legal_names`, and `company_commercial_names`.  
   If a match is found, `name_match_exact = 1`, otherwise `0`.

2. **Location score**  
   - `city_match = 1` if cities are identical  
   - `country_match = 1` if countries are identical  
   - `location_score = city_match + country_match` (range 0–2)

3. **Website match**  
   - Checks if the website domain contains the first 5 characters of the input company name  
   - If yes, `website_match = 1`

### Step 3 – Sort candidates
The dataset is sorted by:
1. `input_row_key`
2. `name_match_exact` (descending)
3. `website_match` (descending)
4. `location_score` (descending)

This ensures that the best-scoring candidate appears first in each group.

### Step 4 – Select one candidate per company
Using `distinct(input_row_key, .keep_all = TRUE)`, only the first (best) row per input company is kept.

### Step 5 – Split results
The filtered list is divided into two categories:
- **Approved** – if `name_match_exact == 1`, or if both `website_match == 1` and `location_score == 2`
- **Manual review** – all remaining rows

Both are exported as:
- `APPROVED.csv`
- `DE_REVIZUIT_MANUAL.csv`

### Step 6 – Quick analysis
The script prints a short summary showing the top 10 industries of the approved suppliers using:

```r
count(main_industry, sort = TRUE)
