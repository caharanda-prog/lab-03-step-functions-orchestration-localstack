def lambda_handler(event, context):
    print("Processing payment:", event)
    
    trace = event.setdefault("trace", [])
    
    if event.get("failAt") == "payment":
      trace.append({
            "step": "payment",
            "status": "failed"
      })  
      raise Exception("Payment process failed intentionally")

    event["status"] = "paid"
    trace.append({
            "step": "payment",
            "status": "ok"
      })
      
    return event