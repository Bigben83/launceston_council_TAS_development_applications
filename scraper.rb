require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'
require 'uri'

logger = Logger.new(STDOUT)

base_url = 'https://onlineservice.launceston.tas.gov.au/eProperty/P1/PublicNotices/'
main_url = "#{base_url}AllPublicNotices.aspx?r=P1.LCC.WEBGUEST&f=%24P1.ESB.PUBNOTAL.ENQ"

begin
  logger.info("Fetching page content from: #{main_url}")
  page_html = open(main_url, "User-Agent" => "Mozilla/5.0").read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

doc = Nokogiri::HTML(page_html)

db = SQLite3::Database.new "data.sqlite"

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS launceston (
    id INTEGER PRIMARY KEY,
    council_reference TEXT,
    description TEXT,
    address TEXT,
    on_notice_to TEXT,
    detail_url TEXT,
    date_scraped TEXT
  );
SQL

date_scraped = Date.today.to_s

doc.css('table.grid').each do |table|
  # Extract Application ID and Detail URL
  app_id_link = table.at_css('a')
  council_reference = app_id_link ? app_id_link.text.strip : 'Unknown'
  detail_url = app_id_link ? URI.join(base_url, app_id_link['href']).to_s : ''

  # Extract Description
  description_row = table.at_css('tr:contains("Application Description") td:nth-child(2)')
  description = description_row ? description_row.text.strip : 'Description not found'

  # Extract Address
  address_row = table.at_css('tr:contains("Property Address") td:nth-child(2)')
  address = address_row ? address_row.text.strip : 'Address not found'

  # Extract Closing Date
  closing_date_row = table.at_css('tr:contains("Closing Date") td:nth-child(2)')
  on_notice_to = closing_date_row ? Date.strptime(closing_date_row.text.strip, "%d/%m/%Y").to_s : ''

  logger.info("Council Reference: #{council_reference}")
  logger.info("Description: #{description}")
  logger.info("Address: #{address}")
  logger.info("Closing Date: #{on_notice_to}")
  logger.info("Detail URL: #{detail_url}")
  logger.info("-----------------------------------")

  existing_entry = db.execute("SELECT * FROM launceston WHERE council_reference = ?", council_reference)

  if existing_entry.empty?
    db.execute("INSERT INTO launceston (council_reference, description, address, on_notice_to, detail_url, date_scraped)
                VALUES (?, ?, ?, ?, ?, ?)",
                [council_reference, description, address, on_notice_to, detail_url, date_scraped])
    logger.info("Data for #{council_reference} saved to database.")
  else
    logger.info("Duplicate entry for #{council_reference} found. Skipping insertion.")
  end
end

logger.info("Scraping completed.")
