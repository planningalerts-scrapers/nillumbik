require "epathway_scraper"

EpathwayScraper::Scraper.scrape_and_save(
  "https://epathway.nillumbik.vic.gov.au/ePathway/Production",
  list_type: :advertising
)
