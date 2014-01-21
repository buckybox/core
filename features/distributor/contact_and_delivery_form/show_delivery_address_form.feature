@javascript
Feature: Distributors are presented with a form to change customer delivery details
  In order for a distributor to have the latest customer delivery details
  As a distributor
  I want to be able view the customers delivery details form

  Scenario: Updating the first line of your address
    Given I am a distributor that collects the first line of an address
    When I am viewing a customers delivery details form
    Then I should see an "Address 1" field

  Scenario: Updating the second line of your address
    Given I am a distributor that collects the second line of an address
    When I am viewing a customers delivery details form
    Then I should see an "Address 2" field

  Scenario: Updating your suburb
    Given I am a distributor that collects a suburb
    When I am viewing a customers delivery details form
    Then I should see a "Suburb" field

  Scenario: Updating your city
    Given I am a distributor that collects a city
    When I am viewing a customers delivery details form
    Then I should see a "City" field

  Scenario: Updating your postcode
    Given I am a distributor that collects a postcode
    When I am viewing a customers delivery details form
    Then I should see a "Postcode" field

  Scenario: Updating your delivery note
    Given I am a distributor that collects a delivery note
    When I am viewing a customers delivery details form
    Then I should see a "Delivery note" field

  Scenario: Updating your delivery note
    Given I am a distributor that does not collect a delivery note
    When I am viewing a customers delivery details form
    Then PENDING: I should not see a "Delivery note" field
