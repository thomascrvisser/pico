ruleset use_twilio_keys {
    meta {
        use module twilio_keys
        use module twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token =  keys:twilio{"auth_token"}
        shares __testing
    }

   global {
        __testing = { 
            "queries": [{ "name": "__testing" } ],
            "events": [ 
                { "domain": "test", "type": "send_message", "attrs": ["to", "from", "message"] },
                { "domain": "test", "type": "get_messages", "attrs": ["to", "from", "pageSize"] }
             ]
            }
    }
 
    rule test_send_sms {
        select when test new_message
        twilio:send_sms(event:attr("to"),
                        event:attr("from"),
                        event:attr("message")
                    )
    }

    rule test_get {
        select when test get_messages
        pre{
            messages = twilio:messages(
                        event:attr("to"),
                        event:attr("from"),
                        event:attr("pageSize")
            )
        }
        send_directive("messages", {"messages": messages})
    }
}