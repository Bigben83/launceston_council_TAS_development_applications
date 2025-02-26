require 'mechanize'
require 'sqlite3'
require 'logger'
require 'date'

logger = Logger.new(STDOUT)

# Initialize Mechanize
agent = Mechanize.new
agent.user_agent_alias = 'Windows Chrome'

begin
  logger.info("Fetching page content...")
  page = agent.get("https://onlineservice.launceston.tas.gov.au/eProperty/P1/PublicNotices/AllPublicNotices.aspx?r=P1.LCC.WEBGUEST&f=%24P1.ESB.PUBNOTAL.ENQ")
  logger.info("Successfully fetched page content.")
  puts page.body  # Debugging: Check if content is returned
rescue Mechanize::ResponseCodeError => e
  logger.error("Failed to fetch page content: HTTP #{e.response_code}")
rescue StandardError => e
  logger.error("Failed to fetch page content: #{e}")
end
