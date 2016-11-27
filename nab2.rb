require 'watir'
require 'pry'
require "base64"
require 'dotenv'

def download_transactions(account, download_directory)
    @browser.link(text: 'Transaction history').wait_until_present.click

    @browser.link(title: 'Click to search for specific transactions').wait_until_present.click

    @browser.select_list(:name => 'periodModeSelect').options.to_a.last.select
    early = (Date.today - 560).strftime('%d/%m/%y')

    @browser.text_field(:id => 'periodFromDateD').wait_until_present.set(early)
    @browser.text_field(:id => 'periodToDateD').wait_until_present.set(Date.today.strftime('%d/%m/%y'))
    # binding.pry
    # puts @browser.select_list(:name => 'transactionsPerPage').options.to_a.map{|m| m.text}
    # puts @browser.select_list(:id => 'selectAccountList').options.to_a.map{|m| m.text}

    @browser.select_list(:id => 'selectAccountList').select(/#{account}/)
    @browser.element(:id => "displayButton").click

    @browser.link(:title => 'Exports transaction history').wait_until_present.click
    # TODO: Select CSV
    @browser.button(:name => 'okButton').wait_until_present.click
    #rename file
    output = File.join(download_directory,"TransactionHistory.csv")
    sleep(0.1) while(!File.exists?(output))
    File.rename(File.join(download_directory,"TransactionHistory.csv"), File.join(download_directory,"#{account}_#{Date.today.to_s}.csv"))
end

begin

    Dotenv.load

    download_directory = File.join(Dir.pwd, "downloads")

    prefs = {
        'download' => {
            'default_directory' => download_directory,
            'prompt_for_download' => false,
            'directory_upgrade' => true,
            'extensions_to_open' => '',
        },
        'profile' => {
            'default_content_settings' => {'multiple-automatic-downloads' => 1}, #for chrome version olde ~42
            'default_content_setting_values' => {'automatic_downloads' => 1}, #for chrome newer 46
            'password_manager_enabled' => false,
            'gaia_info_picture_url' => true,
        }
    }

    caps = Selenium::WebDriver::Remote::Capabilities.chrome
    caps['chromeOptions'] = {'prefs' => prefs}

    @browser = Watir::Browser.new :chrome, :desired_capabilities => caps
    # @browser = Watir::@browser.new #:phantomjs
    @browser.goto 'https://ib.nab.com.au/nabib/index.jsp'
    @browser.text_field(title: 'NAB ID').wait_until_present.set ENV['ACCOUNT_ID']
    @browser.text_field(title: 'Internet Banking password').wait_until_present.set Base64.decode64(ENV['PASSWORD'])
    @browser.link(title: 'Login to NAB Internet banking').wait_until_present.click
    @browser.link(text: 'Transaction history').wait_until_present.click

    all = @browser.select_list(:id => 'selectAccountList').options.to_a[1..-1].map{|c| c.text.split('/')[0]}
    all.each{ |account| download_transactions(account ,download_directory)}

    @browser.link(:id => 'logoutButton').click
    @browser.alert.wait_until_present.ok

    @browser.close

rescue Exception => e

    binding.pry

end