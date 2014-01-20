@javascript
Feature: Customers are presented with a form to change their contact details
  In order for a distributor to have the latest customer contact details
  As a customer
  I want to be able view the contact details form

  Scenario: Updating your name
    Given I am a customer
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form without a "Name"
    Then I should get an error "First name can't be blank"

  Scenario: Updating your email
    Given I am a customer
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form without a "Email"
    Then I should get an error "Email can't be blank"

  Scenario: Updating a phone number
    Given I am a customer for a distributor that does not require phone numbers
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form without a phone number
    Then I should not get an error "Address phone number can't be blank"

  Scenario: Updating a phone number
    Given I am a customer for a distributor that requires phone numbers
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form without a phone number
    Then I should get an error "Address phone number can't be blank"

  Scenario: Updating your mobile phone
    Given I am a customer for a distributor that requires phone numbers
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form with a "Mobile phone" of "111-111-1111"
    Then I should not get an error "Address phone number can't be blank"

  Scenario: Updating your home phone
    Given I am a customer for a distributor that requires phone numbers
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form with a "Home phone" of "111-111-1111"
    Then I should not get an error "Address phone number can't be blank"

  Scenario: Updating your work phone
    Given I am a customer for a distributor that requires phone numbers
    And I am viewing my dashboard
    And I click on "change my contact details"
    When I submit the form with a "Work phone" of "111-111-1111"
    Then I should not get an error "Address phone number can't be blank"
