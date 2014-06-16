@javascript
Feature: Customers are presented with a form to change their contact details
  In order for a distributor to have the latest customer contact details
  As a customer
  I want to be able view the contact details form

  Scenario: Updating your name
    Given I am a customer
    And I am viewing my dashboard
    When I click on "change my contact details"
    Then I should see a "First name" field

  Scenario: Updating your email
    Given I am a customer
    And I am viewing my dashboard
    When I click on "change my contact details"
    Then I should see a "Email" field

  Scenario: Updating your phone number
    Given I am a customer for a distributor that does not collect phone numbers
    And I am viewing my dashboard
    When I click on "change my contact details"
    Then I should not see a "Mobile phone" field
    And I should not see a "Home phone" field
    And I should not see a "Work phone" field

  Scenario: Updating your phone number
    Given I am a customer for a distributor that collects phone numbers
    And I am viewing my dashboard
    When I click on "change my contact details"
    Then I should see a "Mobile phone" field
    And I should see a "Home phone" field
    And I should see a "Work phone" field
