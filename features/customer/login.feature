Feature: Customer logs in
  In order to use the application
  As a customer
  I want to be able to log in and log out

Background:
  Given I am a customer

Scenario: Log in
  When I log in
  Then I should be viewing my profile page

Scenario: Try to log in with invalid credentials
  Given I am viewing the customers login page
  When I fill in invalid credentials
  And  I should be viewing the customers login page

Scenario: Log out
  Given I am viewing my dashboard
  When I log out
  Then I should be logged out

