@javascript
Feature: Existing customer changes their contact details
  In order for a customer to make sure the distributor can contact them
  As a customer
  I want to be able to keep my contact information up to date

  Scenario: Updating your name
    Given I am a customer
    And I am viewing my dashboard
    When I click on "change my contact details"
    Then I should see a "Name" field

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
