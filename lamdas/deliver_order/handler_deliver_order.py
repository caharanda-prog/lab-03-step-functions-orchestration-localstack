def lambda_handler(event, context):
    print("Deliver order:", event)
    
    trace = event.setdefault("trace", [])
    
    if event.get("failAt") == "deliver":
        trace.append({
            "step": "deliver",
            "status": "failed"
        })  
        raise Exception("Deliver process failed intentionally")

    event["status"] = "delivered"
    trace.append({
        "step": "deliver",
        "status": "ok"
    })
    
    return event