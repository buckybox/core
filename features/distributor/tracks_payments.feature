Feature: Distributor tracks payments
  In order to keep track of whether veggies have been paid for
  As a distributor
  I want to be able to track customer payments

Scenario: distributor records payment manually
  Given a distributor looking at their dashboard
  When I submit valid payment details
  Then the payment is recorded against that customer
   And the customer balance increases by the payment amount


