@javascript
Feature: Distributor emails their customers
  In order to keep in touch with my customers
  As a distributor
  I want to be able to email them with a kick-ass emailer

Background:
  Given I am a distributor
  And I am viewing the customers page
  And I select all my customers in the list
  And I open the emailer

Scenario: Send an email
  When I fill in the subject with "My new template"
  And  I fill in the body with "Heya!"
  Then I should be able to send an email

