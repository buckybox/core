@javascript
Feature: Existing customer changes their delivery details
  In order for a customer to get their boxes delivered to the correct address
  As a customer
  I want to be able to keep my address up to date

  Scenario: Updating the first line of your address
    Given I am a customer for a distributor that does not require a first line of an address
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Address 1"
    Then I should not get an error "You must fill in all the required fields."

  Scenario: Updating the first line of your address
    Given I am a customer for a distributor that requires a first line of an address
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Address 1"
    Then I should get an error "You must fill in all the required fields."

  Scenario: Updating the second line of your address
    Given I am a customer for a distributor that does not require a second line of an address
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Address 2"
    Then I should not get an error "You must fill in all the required fields."

  Scenario: Updating the second line of your address
    Given I am a customer for a distributor that requires a second line of an address
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Address 2"
    Then I should get an error "You must fill in all the required fields."

  Scenario: Updating your suburb
    Given I am a customer for a distributor that does not require a suburb
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Suburb"
    Then I should not get an error "You must fill in all the required fields."

  Scenario: Updating your suburb
    Given I am a customer for a distributor that requires a suburb
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Suburb"
    Then I should get an error "You must fill in all the required fields."

  Scenario: Updating your city
    Given I am a customer for a distributor that does not require a city
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "City"
    Then I should not get an error "You must fill in all the required fields."

  Scenario: Updating your city
    Given I am a customer for a distributor that requires a city
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "City"
    Then I should get an error "You must fill in all the required fields."

  Scenario: Updating your postcode
    Given I am a customer for a distributor that does not require a postcode
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Postcode"
    Then I should not get an error "You must fill in all the required fields."

  Scenario: Updating your postcode
    Given I am a customer for a distributor that requires a postcode
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Postcode"
    Then I should get an error "You must fill in all the required fields."

  Scenario: Updating your delivery note
    Given I am a customer for a distributor that does not require a delivery note
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Delivery note"
    Then I should not get an error "You must fill in all the required fields."

  Scenario: Updating your delivery note
    Given I am a customer for a distributor that requires a delivery note
    And I am viewing my dashboard
    And I click on "change my delivery address"
    When I submit the form without a "Delivery note"
    Then I should get an error "You must fill in all the required fields."
