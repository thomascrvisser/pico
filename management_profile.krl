ruleset management_profile {
    meta {
        use module twilio_keys
        use module twilio_v2 alias twilio
            with account_sid = keys:tkeys("account_sid")
            auth_token =  keys:tkeys("auth_token")
        
    }
    
    global {
        default_number = "+18019404120";
        from_number = "+12055767418"
    }

    rule send_text {
        select when management_profile send_message
        pre {
            message = event:attr("message")
            toNumber = ent:number
        }

        twilio:send_sms(toNumber,
                            from_number,
                            message)
    }

    rule initialization {
        select when wrangler ruleset_added where rids >< meta:rid
        always {
            ent:number := default_number;
        }
    }
    rule update_sensor_profile {
        select when sensor profile_updated
        pre {
            sensor_phone_number = event:attr("number").defaultsTo(ent:number)
        }
        
        always {
            ent:number := sensor_phone_number;
        }
    }
}