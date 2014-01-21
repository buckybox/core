@javascript
Feature: Customers are presented with a form to change their delivery details
  In order for a distributor to have the latest customer delivery details
  As a customer
  I want to be able view the delivery details form

  Scenario: Updating the first line of your address
    Given I am a customer for a distributor that collects the first line of an address
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should see an "Address 1" field

  Scenario: Updating the second line of your address
    Given I am a customer for a distributor that collects the second line of an address
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should see an "Address 2" field

  Scenario: Updating your suburb
    Given I am a customer for a distributor that collects a suburb
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should see a "Suburb" field

  Scenario: Updating your city
    Given I am a customer for a distributor that collects a city
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should see a "City" field

  Scenario: Updating your postcode
    Given I am a customer for a distributor that collects a postcode
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should see a "Postcode" field

  Scenario: Updating your delivery note
    Given I am a customer for a distributor that collects a delivery note
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should see a "Delivery note" field

  Scenario: Updating your delivery note
    Given I am a customer for a distributor that does not collect a delivery note
    And I am viewing my dashboard
    When I click on "change my delivery address"
    Then I should not see a "Delivery note" field
