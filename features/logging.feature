Feature:  logging
  Provides a bridge to OpenHAB Logging

  Background:
    Given Clean OpenHAB with latest Ruby Libraries

  Scenario: Logger works after requiring third party gems
    Given a rule
      """
      gemfile do
        source 'https://rubygems.org'
        gem 'nap', '1.1.0'
      end

      logger.info("openHAB Rules!")
      """
    When I deploy the rules file
    Then It should log 'openHAB Rules!' within 5 seconds
