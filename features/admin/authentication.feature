@javascript
Feature: admin authentication
  In order to use the application
  As a admin
  I want to be able to log in and log out

Scenario: Log in with valid credentials
  Given I am viewing the admin login page
  When I fill in valid admin credentials
  Then I should be viewing the admin home page

Scenario: Log in with invalid credentials
  Given I am viewing the admin login page
  When I fill in invalid admin credentials
  Then I should be viewing the admin login page

Scenario: Log out
  Given I am logged in as a admin
  When I log out of the admin section
  Then I should be viewing the admin login page
