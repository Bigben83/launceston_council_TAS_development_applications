require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'sqlite3'
require 'logger'
require 'date'

logger = Logger.new(STDOUT)
url = URI("https://onlineservice.launceston.tas.gov.au/eProperty/P1/PublicNotices/AllPublicNotices.aspx?r=P1.LCC.WEBGUEST&f=%24P1.ESB.PUBNOTAL.ENQ")

begin
  logger.info("Fetching page content from: #{url}")

  # Increase timeout and read the page using Net::HTTP
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = (url.scheme == "https") # Ensure HTTPS is used
  http.open_timeout = 120 # Increase timeout to 2 minutes
  http.read_timeout = 120

  request = Net::HTTP::Get.new(url)
  request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
  response = http.request(request)
  
  if response.code.to_i != 200
    logger.error("Failed to fetch page: HTTP #{response.code}")
    exit
  end

  page_html = response.body
  logger.info("Successfully fetched page content.")
rescue Net::OpenTimeout, Net::ReadTimeout
  logger.error("Failed to fetch page content: request timed out")
  exit
rescue StandardError => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end
