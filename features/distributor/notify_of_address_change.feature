Feature: Distributor gets notified of customer address change
  In order to deliver orders to the correct places
  As a distributor
  I want to be notified when a customers address changes

Background:
  Given I am a distributor
  And I have notify address option turned on

Scenario: Create new customer
  Given I am viewing the customers page
  When  I add a new customer
  Then  I should not receive a notification of the address change

Scenario: Edit existing customer's address
  Given I am viewing an existing customer
  When  I edit the customer's address
  Then  The distributor should receive a notification of the address change

