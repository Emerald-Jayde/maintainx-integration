# MaintainX Integration Tech Assessment
This project implements the structure for an application that receives webhooks from a specific MaintainX instance, manipulates data, and updates objects on the MaintainX instance. 

For the purposes of this assignment, 2 endpoints are made available:
* *work_order_created*: triggered by a new work order created in MaintainX
* *work_order_priority_changed*: triggered by an updated priority on an existing work order in MaintainX

I implemented this app using *service objects* to keep things as modular, maintainable and clean as possible. This will allow us to add different integrations and scale each service independently, so it keeps the application up while we make changes to different parts with minimal downtime.

#### Improvements
This was implemented as a POC. Therefore, there is room for improvements:
* Improved security by adding webhook signature verification
* Implement the services as background jobs
* Implement retry logic
* Better error handling
* Implement/add some kind of auditing service

## How to run
1. Set up ngrok
2. Install dependencies: `bundle install`
3. `ngrok http <PORT> --url <domain-name>.ngrok-free.app`
4. Create the webhooks in MaintainX
```
https://<domain-name>.ngrok-free.app/webhooks/maintainx/wo_created | New Work Order
https://<domain-name>.ngrok-free.app/webhooks/maintainx/wo_priority_changed
 | Work Order Change
```
5. Update MaintainX API token by running `rails credentials:edit`
6. Start the server: `rails s`
