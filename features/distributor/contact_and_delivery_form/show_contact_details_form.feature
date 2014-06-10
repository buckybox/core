@javascript
Feature: Distributors are presented with a form to change customer contact details
  In order for a distributor to update the latest customer contact details
  As a distributor
  I want to be able view the customers contact details form

  Scenario: Updating your name
    Given I am a distributor
    When I am viewing a customers contact details form
    Then I should see a "First name" field

  Scenario: Updating your email
    Given I am a distributor
    When I am viewing a customers contact details form
    Then I should see a "Email" field

  Scenario: Updating your phone number
    Given I am a distributor that does not collect phone numbers
    When I am viewing a customers contact details form
    Then I should not see a "Mobile phone" field
    And I should not see a "Home phone" field
    And I should not see a "Work phone" field

  Scenario: Updating your phone number
    Given I am a distributor that collects phone numbers
    When I am viewing a customers contact details form
    Then I should see a "Mobile phone" field
    And I should see a "Home phone" field
    And I should see a "Work phone" field
