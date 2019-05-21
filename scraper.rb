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

while summary_page
  table = summary_page.root.at_css('table.ContentPanel')
  headers = table.css('th').collect { |th| th.inner_text.strip }

  table.css('.ContentPanel, .AlternateContentPanel').each do |tr|
    da_item = tr.css('td').collect { |td| td.inner_text.strip }
    record = {
      'council_reference' => da_item[headers.index('Application number')],
      # There is a direct link but you need a session to access it :(
      'info_url' => url,
      'description' => da_item[headers.index('Description')],
      'date_received' => Date.strptime(da_item[headers.index('Date lodged')], '%d/%m/%Y').to_s,
      'address' => da_item[headers.index('Location')],
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
