@javascript
Feature: distributor authentication
  In order to use the application
  As a distributor
  I want to be able to log in and log out

Scenario: Log in with valid credentials
  Given I am viewing the distributor login page
  When I fill in valid distributor credentials
  Then I should be viewing the distributor customer list page

Scenario: Log in with invalid credentials
  Given I am viewing the distributor login page
  When I fill in invalid distributor credentials
  Then I should be viewing the distributor login page

Scenario: Log out
  Given I am logged in as a distributor
  When I log out of the distributor section
  Then I should be viewing the distributor login page
