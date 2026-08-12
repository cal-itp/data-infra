resource "google_compute_security_policy" "metabase-staging" {
  name        = "metabase-staging-armor"
  description = "Cloud Armor policy protecting Metabase Cloud Run (staging)"

  rule {
    priority    = 500
    action      = "deny(403)"
    description = "Geo-restrict to US/CA/GB/NL/HU"
    match {
      expr {
        expression = "!(origin.region_code == 'US' || origin.region_code == 'CA' || origin.region_code == 'GB' || origin.region_code == 'NL' || origin.region_code == 'HU')"
      }
    }
  }

  rule {
    priority    = 1000
    action      = "deny(403)"
    description = "OWASP SQLi"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1, 'opt_out_rule_ids': ['owasp-crs-v030301-id942420-sqli']}) && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1100
    action      = "deny(403)"
    description = "OWASP XSS"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': 1, 'opt_out_rule_ids': ['owasp-crs-v030301-id941340-xss']}) && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1200
    action      = "deny(403)"
    description = "OWASP RCE"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1, 'opt_out_rule_ids': ['owasp-crs-v030301-id932200-rce']}) && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1300
    action      = "deny(403)"
    description = "OWASP local file inclusion"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('lfi-v33-stable') && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1400
    action      = "deny(403)"
    description = "OWASP remote file inclusion"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('rfi-v33-stable') && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1500
    action      = "deny(403)"
    description = "Scanner / bot signatures"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 1, 'opt_out_rule_ids': ['owasp-crs-v030301-id913101-scannerdetection']}) && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1600
    action      = "deny(403)"
    description = "HTTP protocol attacks"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('protocolattack-v33-stable', {'sensitivity': 1, 'opt_out_rule_ids': ['owasp-crs-v030301-id921170-protocolattack']}) && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 1700
    action      = "deny(403)"
    description = "Session fixation"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sessionfixation-v33-stable') && !request.path.startsWith('/api/dataset') && !request.path.startsWith('/api/card') && !request.path.startsWith('/api/dashboard')"
      }
    }
  }

  rule {
    priority    = 9000
    action      = "rate_based_ban"
    description = "Per-IP login rate limit (10/min then 10-min ban)"
    match {
      expr {
        expression = "request.path.startsWith('/api/session') && request.method == 'POST' && !inIpRange(origin.ip, '149.136.0.0/16')"
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600
      rate_limit_threshold {
        count        = 10
        interval_sec = 60
      }
      ban_threshold {
        count        = 10
        interval_sec = 60
      }
    }
  }

  rule {
    priority    = 9100
    action      = "throttle"
    description = "Per-IP global throttle (1200/min)"
    match {
      expr {
        expression = "!inIpRange(origin.ip, '149.136.0.0/16')"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 1200
        interval_sec = 60
      }
    }
  }

  rule {
    priority    = 2147483647
    action      = "allow"
    description = "Default allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
