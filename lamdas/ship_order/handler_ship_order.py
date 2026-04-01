def lambda_handler(event, context):
    print("Shipping order:", event)
    
    trace = event.setdefault("trace", [])
    
    if event.get("failAt") == "ship":
      trace.append({
            "step": "ship",
            "status": "failed"
      })  
      raise Exception("Shipping process failed intentionally")
    
    event["status"] = "shipped"
    trace.append({
            "step": "ship",
            "status": "ok"
      })
      
    return event