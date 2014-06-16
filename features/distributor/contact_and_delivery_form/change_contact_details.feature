@javascript
Feature: Distributor changes the customers contact details
  In order for a distributor to make sure they have current contact details
  As a distributor
  I want to be able to keep the customers contact information up to date

  Scenario: Updating your name
    Given I am a distributor
    And I am viewing a customers contact details form
    When I submit the form without a "First name"
    Then I should get an error "Oops there was an issue:"

  Scenario: Updating your email
    Given I am a distributor
    And I am viewing a customers contact details form
    When I submit the form without a "Email"
    Then I should get an error "Oops there was an issue:"

  Scenario: Updating a phone number
    Given I am a distributor that does not require phone numbers
    And I am viewing a customers contact details form
    When I submit the form without a phone number
    Then I should not get an error "Oops there was an issue:"

  Scenario: Updating a phone number
    Given I am a distributor that requires phone numbers
    And I am viewing a customers contact details form
    When I submit the form without a phone number
    Then I should get an error "Oops there was an issue:"

  Scenario: Updating your mobile phone
    Given I am a distributor that requires phone numbers
    And I am viewing a customers contact details form
    When I submit the form with a "Mobile phone" of "111-111-1111"
    Then I should not get an error "Oops there was an issue:"

  Scenario: Updating your home phone
    Given I am a distributor that requires phone numbers
    And I am viewing a customers contact details form
    When I submit the form with a "Home phone" of "111-111-1111"
    Then I should not get an error "Oops there was an issue:"

  Scenario: Updating your work phone
    Given I am a distributor that requires phone numbers
    And I am viewing a customers contact details form
    When I submit the form with a "Work phone" of "111-111-1111"
    Then I should not get an error "Oops there was an issue:"
