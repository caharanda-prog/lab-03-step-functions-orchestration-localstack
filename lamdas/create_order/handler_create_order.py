def lambda_handler(event, context):
    print("create order:", event)
    
    trace = event.setdefault("trace", [])

    event["status"] = "created"
    trace.append({
            "step": "create",
            "status": "ok"
      })
      
    return event