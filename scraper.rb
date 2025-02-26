require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'

# Set up a logger to log the scraped data
logger = Logger.new(STDOUT)

# Define the URL of the page
url = "https://onlineservice.launceston.tas.gov.au/eProperty/P1/PublicNotices/AllPublicNotices.aspx?r=P1.LCC.WEBGUEST&f=%24P1.ESB.PUBNOTAL.ENQ"

# Step 1: Fetch the page content
begin
  logger.info("Fetching page content from: #{url}")
  page_html = open(url).read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

# Step 2: Parse the page content using Nokogiri
page = Nokogiri::HTML(page_html)

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create a table specific to Tasman Council if it doesn't exist
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS launceston (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_scraped TEXT,
    date_received TEXT,
    on_notice_to TEXT,
    address TEXT,
    council_reference TEXT,
    applicant TEXT,
    owner TEXT,
    stage_description TEXT,
    stage_status TEXT,
    document_description TEXT,
    title_reference TEXT
  );
SQL

# Define variables for storing extracted data for each entry
address = ''  
description = ''
on_notice_to = ''
title_reference = ''
date_received = ''
council_reference = ''
applicant = ''
owner = ''
stage_description = ''
stage_status = ''
document_description = ''
date_scraped = Date.today.to_s

logger.info("Start Extraction of Data")
logger.info("Start Extraction of Data")

# Loop through each application table
page.css('table.grid').each do |table|
  council_reference = table.at_css('a')&.text&.strip
  application_url = table.at_css('a')&.[]('href')
  application_url = URI.join(url, application_url).to_s if application_url

  description = table.xpath(".//td[contains(text(), 'Application Description')]/following-sibling::td").text.strip
  address = table.xpath(".//td[contains(text(), 'Property Address')]/following-sibling::td").text.strip
  on_notice_to_raw = table.xpath(".//td[contains(text(), 'Closing Date')]/following-sibling::td").text.strip

  # Convert Closing Date to YYYY-MM-DD format
  begin
    on_notice_to = Date.strptime(on_notice_to_raw, '%d/%m/%Y').to_s
  rescue ArgumentError
    on_notice_to = "Invalid Date"
  end

  # Log the extracted data
  logger.info("Council Reference: #{council_reference}")
  logger.info("Description: #{description}")
  logger.info("Address: #{address}")
  logger.info("Closing Date: #{on_notice_to}")
  logger.info("Application URL: #{application_url}")
  logger.info("-----------------------------------")

  # Ensure the entry does not already exist before inserting
  existing_entry = db.execute("SELECT * FROM launceston WHERE council_reference = ?", council_reference)

  if existing_entry.empty?
    db.execute("INSERT INTO launceston 
      (council_reference, description, address, on_notice_to, date_scraped, application_url) 
      VALUES (?, ?, ?, ?, ?, ?)",
      [council_reference, description, address, on_notice_to, date_scraped, application_url])

    logger.info("Data for #{council_reference} saved to database.")
  else
    logger.info("Duplicate entry for document #{council_reference} found. Skipping insertion.")
  end
end

logger.info("Data has been successfully inserted into the database.")
