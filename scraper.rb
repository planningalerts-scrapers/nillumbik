require "epathway_scraper"

base_url = "https://epathway.nillumbik.vic.gov.au/ePathway/Production/web/GeneralEnquiry/"
url = "#{base_url}enquirylists.aspx"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.nillumbik.vic.gov.au/ePathway/Production"
)
agent = scraper.agent

summary_page = scraper.pick_type_of_search(:advertising)

while summary_page
  table = summary_page.root.at_css('table.ContentPanel')

  scraper.extract_table_data_and_urls(table).each do |row|
    data = scraper.extract_index_data(row)
    record = {
      'council_reference' => data[:council_reference],
      # There is a direct link but you need a session to access it :(
      'info_url' => scraper.base_url,
      'description' => data[:description],
      'date_received' => data[:date_received],
      'address' => data[:address],
      'date_scraped' => Date.today.to_s
    }
    EpathwayScraper.save(record)
  end

  next_page_img = summary_page.root.at_xpath("//a/img[contains(@src, 'nextPage')]")
  summary_page = nil
  if next_page_img
    p "Found another page"
    summary_page = agent.get "#{base_url}#{next_page_img.parent['href']}"
  end
end
