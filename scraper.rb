require 'selenium-webdriver'
require 'sqlite3'
require 'logger'
require 'date'

logger = Logger.new(STDOUT)

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')  # Run in the background

driver = Selenium::WebDriver.for :chrome, options: options
driver.navigate.to "https://onlineservice.launceston.tas.gov.au/eProperty/P1/PublicNotices/AllPublicNotices.aspx?r=P1.LCC.WEBGUEST&f=%24P1.ESB.PUBNOTAL.ENQ"

puts driver.page_source  # Check if data loads

driver.quit
