
# Pasul 1 incarcare set date si librarii necesare -------------------------

library(tidyverse)
# voi incarca setul de date prin File -> Import Dataset -> From Text (readr)... deoarece este csv

# pentru a fi mai usor de lucrat am ales sa schimb numele
date_curate <- presales_data_sample
rm(presales_data_sample)

# pentru o functionare corecta, umplu golurile din variabila input_row_key
date_curate <- fill(date_curate, input_row_key, .direction="down")


# Pasul 2 Crearea logicii de alegere a candidatilor  ----------------------

# pentru a adauga coloana, utilizez functia mutate
date_logice <- mutate(
  date_curate, 
  # prima abordare, potrivirea numelui companiilor (logica cu | SAU)
  name_match_exact = ifelse(
    tolower(input_company_name) == (company_name) |
    tolower(input_company_name) == tolower(company_legal_names) |
    tolower(input_company_name) == tolower(company_commercial_names),
    1, 0
), 
  name_match_exact=ifelse(is.na(name_match_exact), 0, name_match_exact), 
  
  # a doua abordare, potrivire locatie
  city_match = ifelse(input_main_city == main_city, 1, 0), 
  country_match = ifelse(input_main_country_code == main_country_code, 1, 0), 
  location_score = city_match + country_match,
  # a treia abordare, potrivirea website-ului
  website_match = ifelse(
    str_detect(tolower(website_domain), 
               fixed(tolower(str_sub(input_company_name, 1, 5)))), 
  1, 0),
)


# Pasul 3 Sortarea --------------------------------------------------------

date_sortate <- arrange(date_logice, 
                        input_row_key, 
                        desc(name_match_exact), 
                        desc(website_match), 
                        desc(location_score)
                        )


# Pasul 4 Alegerea celui mai bun ------------------------------------------


lista_finala <- distinct(date_sortate, 
                         input_row_key, 
                         .keep_all = TRUE)



# Pasul 5 Impartirea in categorii -----------------------------------------

date_aprobate_final <- filter(lista_finala,
                              name_match_exact == 1 | (website_match == 1 & location_score == 2)
)

date_revizuire_manuala <- filter(lista_finala,
                                 !(name_match_exact == 1 | (website_match == 1 & location_score == 2))
)


# Pasul 6 Export CSV cu datele de revizuit manual -------------------------


write.csv(date_revizuire_manuala, "DE_REVIZUIT_MANUAL.csv", row.names = FALSE)
write.csv(date_aprobate_final, "APPROVED.csv", row.names = FALSE)

# Pasul 6 Analiza cu datele aprobate pentru client

print("Top 10 industrii ale furnizorilor aprobati:")
analiza_industrie <- date_aprobate_final %>%
              count(main_industry, sort=TRUE)  # aceasta comanda numara cati furnizori sunt din fiecare industrie
print(head(analiza_industrie, 10))

