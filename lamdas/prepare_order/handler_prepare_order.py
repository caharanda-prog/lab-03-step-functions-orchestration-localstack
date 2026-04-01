def lambda_handler(event, context):
    print("Prepare order:", event)
    
    trace = event.setdefault("trace", [])
    
    if event.get("failAt") == "prepare":
      trace.append({
            "step": "prepare",
            "status": "failed"
      })  
      raise Exception("Prepare process failed intentionally")

    event["status"] = "prepared"
    trace.append({
            "step": "prepare",
            "status": "ok"
    })
    
    return event