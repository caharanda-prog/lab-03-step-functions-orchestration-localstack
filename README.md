# Lab 03 - Step Functions Orchestration (LocalStack)

Event-driven workflow orchestration using AWS Step Functions executed locally with LocalStack.
This lab focuses on orchestration observability, retry behavior, and execution history analysis instead of Lambda-level logging.

---

## 🎯 Overview

This lab demonstrates workflow orchestration using AWS Step Functions running locally with LocalStack.

A multi-step order processing workflow is implemented using Lambda functions:

* Create Order
* Process Payment
* Prepare Order
* Ship Order
* Deliver Order

The lab emphasizes:

* Orchestration-level observability
* Controlled failures
* Retry policies
* Execution history analysis
* Clean separation between orchestration and business logic

Instead of focusing on Lambda logs, the lab highlights the Step Functions execution history as the primary observability mechanism.

---

## 🏗️ Architecture Overview

The workflow is orchestrated using AWS Step Functions with five Lambda tasks.
A producer script generates multiple events to simulate concurrent order processing.

Key characteristics:

* Centralized orchestration
* Stateless Lambda functions
* Retry configuration at orchestration level
* Execution history as main observability source
* Infrastructure defined using Terraform

---

## ⚙️ Tech Stack

* AWS Step Functions (via LocalStack)
* AWS Lambda (Python)
* Terraform
* Docker
* LocalStack
* Bash / CLI scripts

---

## 📁 Project Structure

```
.
├── lambdas/
│   ├── create_order/
│   ├── deliver_order/
│   ├── prepare_order/
│   ├── process_payment/
│   └── ship_order/
│
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│
├── producer/
│   └── order_producer.py
│
└── README.md
```

---

## 📋 Prerequisites

* Docker
* Terraform
* Python 3.x
* AWS CLI configured for LocalStack
* LocalStack running

---

## 🚀 How to Run

### Start LocalStack

Example using Docker:

```
docker run -d
--name localstack-main
-p 4566:4566
-e SERVICES=lambda,iam,stepfunctions,logs
-e DEBUG=1
-e LAMBDA_EXECUTOR=docker
-v /var/run/docker.sock:/var/run/docker.sock
localstack/localstack:latest
```

This configuration explicitly enables the services required for this lab:

- Lambda execution
- Step Functions orchestration
- IAM role simulation
- CloudWatch logs support

The Docker socket mount allows LocalStack to dynamically start Lambda containers.

---

### Deploy Infrastructure

```
terraform init
terraform apply -auto-approve
```

This creates:

* Lambda functions
* Step Functions state machine
* IAM roles
* Integration wiring

---

### Send Test Events

```
python producer/order_producer.py
```

The producer generates multiple order events with randomized data to simulate different execution scenarios.

Each event contains:

- Random customer
- Random order amount
- Unique execution ID
- Random failure injection point

Example event structure:

```json
{
  "executionId": "uuid",
  "orderId": 1234,
  "customer": "Cesar",
  "amount": 250,
  "failAt": "payment"
}
```

The failAt field is randomly assigned and may target different workflow steps:
- payment
- prepare
- ship
- deliver
- none (successful execution)

This randomness allows:

- Testing retry behavior
- Observing failures in different steps
- Validating orchestration resilience
- Visualizing execution history variability

This approach simulates real-world distributed system behavior instead of fixed test cases.


---

## 🔄 Workflow Flow

The workflow executes the following sequence:

1. CreateOrder
2. ProcessPayment
3. PrepareOrder
4. ShipOrder
5. DeliveryOrder

Retry policies are configured at the Step Functions level.

When a failure occurs:

* Step Functions retries the task
* Lambda receives the same event
* No retry logic exists inside Lambda
* Execution history shows retry attempts

This demonstrates orchestration-managed resiliency.

---

## 👀 Observability

### Why Execution History Instead of Lambda Logs

This lab intentionally focuses on Step Functions execution history rather than individual Lambda logs.

Reasons:

* Centralized observability
* Clear visualization of retries
* Workflow-level debugging
* Avoid mixing orchestration with business logic
* Stateless Lambda design

This reflects real-world orchestration practices.

---

### Viewing Execution History

First, list all state machines to obtain the ARN:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions list-state-machines

Example output:

{
    "stateMachines": [
        {
            "stateMachineArn": "arn:aws:states:us-east-1:000000000000:stateMachine:order_flow",
            "name": "order_flow",
            "type": "STANDARD",
            "creationDate": "2026-03-31T10:21:04.185191-06:00"
        }
    ]
}
```

Copy the stateMachineArn from the output and use it in the following command to view the latest 10 executions and detect any Lambda failures  

```bash
(aws --endpoint-url=http://localhost:4566 stepfunctions list-executions --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:order_flow --max-results 10 --query "executions[].executionArn" --output text).Split("`t") | ForEach-Object { 
    Write-Host "`nExecution: $_"; 
    aws --endpoint-url=http://localhost:4566 stepfunctions get-execution-history --execution-arn $_ --query "events[?type=='LambdaFunctionFailed'].{time:timestamp,error:lambdaFunctionFailedEventDetails.error,cause:lambdaFunctionFailedEventDetails.cause}" 
}
```

This command retrieves the latest 10 executions.
Since the producer sends events in batches of 10, the output typically corresponds to one generated batch.

Retries are grouped within each execution, allowing you to observe retry attempts, failures, and eventual success for every individual order processed.

```
Execution: arn:aws:states:us-east-1:000000000000:execution:order_flow:0ed94f1f-4030-44ec-af16-3b7a56a08bc7
[
    {
        "time": "2026-03-31T16:22:56.152268-06:00",
        "error": "Exception",
        "cause": "{\"errorMessage\":\"Shipping process failed intentionally\",\"errorType\":\"Exception\",\"requestId\":\"f58f6d23-4752-468a-b49d-f7ea6acf081a\",\"stackTrace\":[\"  File \\\"/var/task/handler_ship_order.py\\\", line 11, in lambda_handler\\n    raise Exception(\\\"Shipping process failed intentionally\\\")\\n\"]}"
    },
    {
        "time": "2026-03-31T16:22:57.173985-06:00",
        "error": "Exception",
        "cause": "{\"errorMessage\":\"Shipping process failed intentionally\",\"errorType\":\"Exception\",\"requestId\":\"5a43cdab-1bfa-44a1-8726-7743266b9c65\",\"stackTrace\":[\"  File \\\"/var/task/handler_ship_order.py\\\", line 11, in lambda_handler\\n    raise Exception(\\\"Shipping process failed intentionally\\\")\\n\"]}"
    },
    {
        "time": "2026-03-31T16:22:59.220682-06:00",
        "error": "Exception",
        "cause": "{\"errorMessage\":\"Shipping process failed intentionally\",\"errorType\":\"Exception\",\"requestId\":\"226c08bc-2f3a-43ff-bb51-80ff9d9a26a8\",\"stackTrace\":[\"  File \\\"/var/task/handler_ship_order.py\\\", line 11, in lambda_handler\\n    raise Exception(\\\"Shipping process failed intentionally\\\")\\n\"]}"
    }
]
```

This makes it easier to analyze resiliency behavior across multiple simulated scenarios.

---

## 💡 What This Lab Demonstrates

* Workflow orchestration
* Retry policies
* Timeout configuration
* Failure injection
* Execution history observability
* Stateless Lambda design
* Infrastructure as code deployment
* Local AWS emulation

---

## 🧠 Key Concepts

### Orchestration vs Business Logic

Retries are handled by Step Functions, not by Lambda functions.

This keeps Lambdas:

* Stateless
* Simple
* Reusable

---

### ResultPath Strategy

The following configuration is applied to each task in the state machine:

``` HCL
CreateOrder = {
    Type       = "Task"
    Resource   = aws_lambda_function.create_order.arn
    ResultPath = "$"
    Next       = "ProcessPayment"
}
```

This setting is applied in the ResultPath field of each task.

This prevents overwriting the original event and preserves the full payload across steps. By doing this, all the business data from previous steps (like orderId, customer, amount, and execution metadata) is available throughout the workflow.

Using ResultPath = "$" in each task is a practical technique often applied in real-world serverless workflows. It ensures traceability of events. Avoids losing important fields when Lambda outputs are merged with the workflow input.

---

### LocalStack for Orchestration Testing

LocalStack allows:

* Local execution of Step Functions
* Fast iteration
* No AWS costs
* Reproducible environment

This enables realistic orchestration testing.

---

## 🧹 Clean Up

```
terraform destroy -auto-approve
```

Stops and removes all infrastructure created for the lab.

---

## 📝 Notes

* This lab intentionally avoids business logic complexity
* Observability is centered on Step Functions
* Lambda logs are secondary
* Retry logic is orchestration-driven
* ResultPath strategy preserves event data
* Designed as a practical orchestration reference

---

## 🧭 Architecture Diagram
```
┌───────────────────────────┐
│        Producer           │
│    Generates Orders       │
│     (Python Script)       │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│      Step Functions       │
│       Orchestrator        │
│     (State Machine)       │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│          Task             │
│      Create Order         │
│        (Lambda)           │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│          Task             │
│     Process Payment       │
│        (Lambda)           │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│          Task             │
│      Prepare Order        │
│        (Lambda)           │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│          Task             │
│       Ship Order          │
│        (Lambda)           │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│          Task             │
│     Deliver Order         │
│        (Lambda)           │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│    Execution Completed    │
│     (Success / Failure)   │
│    Observed in History    │
└───────────────────────────┘
```
