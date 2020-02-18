ruleset wovyn_base {
    meta {
        use module twilio_keys
        use module twilio_v2 alias twilio
            with account_sid = keys:tkeys{"account_sid"}
            auth_token =  keys:tkeys{"auth_token"}
        use module sensor_profile
        shares __testing
    }
    global {
        __testing = { "queries": [ { "name": "__testing" } ],
                    "events": [ { "domain": "wovyn", "type": "heartbeat",
                                "attrs": [ "genericThing" ] } ] }
        // temperature_threshold = 80
        // violation_phone_number = "+18019404120"
        from_number = "+12055767418"
    }

  rule threshold_notification {
      select when wovyn threshold_violation
      twilio:send_sms(sensor_profile:get_profile(){"number"},
                        from_number,
                        "Temp violation: " + event:attr("temperature") + " on " + event:attr("timestamp")
                        )
  }

  rule find_high_temps {
      select when wovyn new_temperature_reading
      pre {
          temp = event:attr("temperature")
          threshold = sensor_profile:get_profile(){"high"}.as("Number")
          violation = (temp > threshold)
      }

      if violation then
        send_directive("temp_violation", {"occurred": violation})

      fired {
          raise wovyn event "threshold_violation"
            attributes event:attrs
      }
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat where genericThing
    pre {
        temp = event:attr("genericThing"){"data"}{"temperature"}[0]{"temperatureF"}.klog()
        timestamp = time:now()
    }

    send_directive("heartbeat", {"data": temp})

    fired {
        raise wovyn event "new_temperature_reading"
            attributes {"temperature": temp, "timestamp": timestamp}
    }
  }
}