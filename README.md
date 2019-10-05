# Test Automation Framework Template (TAFT)

This gem will deploy/install a skeleton code framework for the automated testing of applications with APIs and/or web-UIs.

Languages : Ruby

## How to use

Command line : `ruby -e "require 'taft'; Taft.install"`
This will prompt you for all pertinent parameters.

## Post-deployment

TAFT deploys a skeleton code framework that attempts to cover several common test areas. These often include the use of additional libraries. To reduce deployment bloat, TAFT will **not** attempt to install those additional libraries. You must install them yourself (using your preferred lib-manager), or deactivate the skeleton code that calls these libraries.


## TODO 

* More languages : Java, Python, Golang