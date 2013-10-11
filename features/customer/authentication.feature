@javascript
Feature: Customer authentication
  In order to use the application
  As a customer
  I want to be able to log in and log out

Scenario: Log in with valid credentials
  Given I am viewing the customer login page
  When I fill in valid customer credentials
  Then I should be viewing the customer home page

Scenario: Log in with invalid credentials
  Given I am viewing the customer login page
  When I fill in invalid customer credentials
  Then I should be viewing the customer login page

Scenario: Log out
  Given I am logged in as a customer
  When I log out of the customer section
  Then I should be viewing the webstore
