require "epathway_scraper"

base_url = "https://epathway.nillumbik.vic.gov.au/ePathway/Production/web/GeneralEnquiry/"
url = "#{base_url}enquirylists.aspx"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.nillumbik.vic.gov.au/ePathway/Production"
)
agent = scraper.agent

first_page = agent.get url
first_page_form = first_page.forms.first
first_page_form.radiobuttons[2].click
summary_page = first_page_form.click_button

das_data = []
while summary_page
  table = summary_page.root.at_css('table.ContentPanel')
  headers = table.css('th').collect { |th| th.inner_text.strip }

  das_data = das_data + table.css('.ContentPanel, .AlternateContentPanel').collect do |tr|
    tr.css('td').collect { |td| td.inner_text.strip }
  end

  next_page_img = summary_page.root.at_xpath("//a/img[contains(@src, 'nextPage')]")
  summary_page = nil
  if next_page_img
    p "Found another page"
    summary_page = agent.get "#{base_url}#{next_page_img.parent['href']}"
  end
end

das = das_data.collect do |da_item|
  page_info = {}
  page_info['council_reference'] = da_item[headers.index('Application number')]
  # There is a direct link but you need a session to access it :(
  page_info['info_url'] = url
  page_info['description'] = da_item[headers.index('Description')]
  page_info['date_received'] = Date.strptime(da_item[headers.index('Date lodged')], '%d/%m/%Y').to_s
  page_info['address'] = da_item[headers.index('Location')]
  page_info['date_scraped'] = Date.today.to_s

  page_info
end

das.each do |record|
  EpathwayScraper.save(record)
end
