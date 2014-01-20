@javascript
Feature: Customers are presented with a form to change their delivery details
  In order for a distributor to have the latest customer delivery details
  As a customer
  I want to be able view the delivery details form

  Background:
    Given I am a customer
    And I am viewing my dashboard
    And I click on "change my delivery address"

  Scenario: Updating the first line of your address
    Given the distributor requires a first line of an address
    When I submit the form without a "Address 1"
    Then I should get an error

  Scenario: Updating the second line of your address
    Given the distributor requires a second line of an address
    When I submit the form without a "Address 2"
    Then I should get an error

  Scenario: Updating your suburb
    Given the distributor requires a suburb
    When I submit the form without a "Suburb"
    Then I should get an error

  Scenario: Updating your city
    Given the distributor requires a city
    When I submit the form without a "City"
    Then I should get an error

  Scenario: Updating your postcode
    Given the distributor requires a postcode
    When I submit the form without a "Postcode"
    Then I should get an error

  Scenario: Updating your delivery note
    Given the distributor requires a delivery note
    When I submit the form without a "Delivery note"
    Then I should get an error
