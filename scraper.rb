require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'

# Set up a logger to log the scraped data
logger = Logger.new(STDOUT)

# Define the URL of the page
url = "https://onlineservice.launceston.tas.gov.au/eProperty/P1/PublicNotices/AllPublicNotices.aspx?r=P1.LCC.WEBGUEST&f=%24P1.ESB.PUBNOTAL.ENQ"

# Step 1: Fetch the page content with improved error handling
begin
  logger.info("Fetching page content from: #{url}")
  page_html = URI.open(url).read
  logger.info("Successfully fetched page content.")
rescue OpenURI::HTTPError => e
  logger.error("HTTP Error: #{e.message}")
  exit
rescue StandardError => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

# Step 2: Parse the page content using Nokogiri
doc = Nokogiri::HTML(page_html)

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create a table specific to Launceston Council if it doesn't exist
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

# Loop through each application table (each one is a separate planning application)
doc.css('table.grid').each do |table|
  # Extract application details from each table
  council_reference = table.at_css('a')&.text&.strip
  application_url = table.at_css('a')&.[]('href')
  application_url = URI.join(url, application_url).to_s if application_url

  description = table.at_xpath('.//tr[td[contains(text(), "Application Description")]]/td[2]')&.text&.strip
  address = table.at_xpath('.//tr[td[contains(text(), "Property Address")]]/td[2]')&.text&.strip
  on_notice_to_raw = table.at_xpath('.//tr[td[contains(text(), "Closing Date")]]/td[2]')&.text&.strip

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

  # Step 4: Ensure the entry does not already exist before inserting
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
