import boto3
import json
import random
import time
import uuid


class OrderProducer:

    def __init__(self):
        self.client = boto3.client(
            "stepfunctions",
            endpoint_url="http://localhost:4566",
            region_name="us-east-1",
            aws_access_key_id="test",
            aws_secret_access_key="test"
        )

        self.state_machine_arn = self._get_state_machine_arn()
        print(f"Using State Machine ARN: {self.state_machine_arn}")
        
    def _get_state_machine_arn(self):
        response = self.client.list_state_machines()

        if not response["stateMachines"]:
            raise Exception("No Step Functions state machines found in LocalStack")
            
        # assuming single state machine for this lab
        return response["stateMachines"][0]["stateMachineArn"]    

    def generate_order(self):
        
        fail_options = [None, "payment", "prepare", "ship", "deliver"]
        
        return {
            "executionId": str(uuid.uuid4()),
            "orderId": random.randint(1000, 9999),
            "customer": random.choice(["Cesar", "Ana", "Luis", "Maria"]),
            "amount": random.randint(50, 500),
            "failAt": random.choice(fail_options)
        }

    def send_event_order(self, order):
        response = self.client.start_execution(
            stateMachineArn=self.state_machine_arn,
            input=json.dumps(order)
        )
        print("Execution started:", response["executionArn"])

    def run(self, total=10, delay=1):
        for _ in range(total):
            order = self.generate_order()
            print("Sending order:", order)
            self.send_event_order(order)
            time.sleep(delay)


if __name__ == "__main__":
    producer = OrderProducer()
    producer.run()