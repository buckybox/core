Feature: Distributor manages customers
  In order to sell veggies to customers
  As a distributor
  I want to be able to manage a list of customers

Background:
  Given I am a distributor

@wip
Scenario: Create new customer
  Given I am viewing the customers page
  When  I add a new customer
  Then  I should be viewing the customer
  And   The customer should be on the customers index page

@wip
Scenario: Edit existing customer
  Given I am viewing an existing customer
  When  I edit the customer's details
   And  I change the customer's first name to "Frodo"
  Then  The customer's page should show the name "Frodo"

