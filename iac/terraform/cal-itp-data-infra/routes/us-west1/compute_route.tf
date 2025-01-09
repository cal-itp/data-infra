resource "google_compute_route" "tfer--default-route-0139828d38125997" {
  description = "Default local route to the subnetwork 10.194.0.0/20."
  dest_range  = "10.194.0.0/20"
  name        = "default-route-0139828d38125997"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-0ac6037fe0939a6f" {
  description = "Default local route to the subnetwork 10.140.0.0/20."
  dest_range  = "10.140.0.0/20"
  name        = "default-route-0ac6037fe0939a6f"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-0c143617340a50b2" {
  description = "Default local route to the subnetwork 10.154.0.0/20."
  dest_range  = "10.154.0.0/20"
  name        = "default-route-0c143617340a50b2"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-116f54cd43aa76b8" {
  description = "Default local route to the subnetwork 10.202.0.0/20."
  dest_range  = "10.202.0.0/20"
  name        = "default-route-116f54cd43aa76b8"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-1777237a0410d42b" {
  description = "Default local route to the subnetwork 10.15.0.0/17."
  dest_range  = "10.15.0.0/17"
  name        = "default-route-1777237a0410d42b"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-19a4b61e3f1d1dca" {
  description = "Default local route to the subnetwork 10.188.0.0/20."
  dest_range  = "10.188.0.0/20"
  name        = "default-route-19a4b61e3f1d1dca"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-38c79629ce32c661" {
  description = "Default local route to the subnetwork 10.156.0.0/20."
  dest_range  = "10.156.0.0/20"
  name        = "default-route-38c79629ce32c661"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-39db8960eeb0345b" {
  description = "Default local route to the subnetwork 10.216.0.0/20."
  dest_range  = "10.216.0.0/20"
  name        = "default-route-39db8960eeb0345b"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-42045736719c6b0e" {
  description = "Default local route to the subnetwork 10.180.0.0/20."
  dest_range  = "10.180.0.0/20"
  name        = "default-route-42045736719c6b0e"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-4a38f1955a65b67e" {
  description = "Default local route to the subnetwork 10.190.0.0/20."
  dest_range  = "10.190.0.0/20"
  name        = "default-route-4a38f1955a65b67e"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-4fe99ee4d30bf242" {
  description = "Default local route to the subnetwork 10.172.0.0/20."
  dest_range  = "10.172.0.0/20"
  name        = "default-route-4fe99ee4d30bf242"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-50fb446fc0c013bf" {
  description = "Default local route to the subnetwork 10.128.0.0/20."
  dest_range  = "10.128.0.0/20"
  name        = "default-route-50fb446fc0c013bf"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-5698a55f5a20cff3" {
  description      = "Default route to the Internet."
  dest_range       = "0.0.0.0/0"
  name             = "default-route-5698a55f5a20cff3"
  network          = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  next_hop_gateway = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/gateways/default-internet-gateway"
  priority         = "1000"
  project          = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-5aaf2bf0470ef1c5" {
  description = "Default local route to the subnetwork 10.162.0.0/20."
  dest_range  = "10.162.0.0/20"
  name        = "default-route-5aaf2bf0470ef1c5"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-5cf5cd160fd0ec13" {
  description = "Default local route to the subnetwork 10.206.0.0/20."
  dest_range  = "10.206.0.0/20"
  name        = "default-route-5cf5cd160fd0ec13"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-5d29eb6a6b21a625" {
  description = "Default local route to the subnetwork 10.96.0.0/14."
  dest_range  = "10.96.0.0/14"
  name        = "default-route-5d29eb6a6b21a625"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-65d3cb41875a5673" {
  description = "Default local route to the subnetwork 10.184.0.0/20."
  dest_range  = "10.184.0.0/20"
  name        = "default-route-65d3cb41875a5673"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-6e0e1f80e7bb481d" {
  description = "Default local route to the subnetwork 10.148.0.0/20."
  dest_range  = "10.148.0.0/20"
  name        = "default-route-6e0e1f80e7bb481d"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-6e9e558a311d758b" {
  description = "Default local route to the subnetwork 10.152.0.0/20."
  dest_range  = "10.152.0.0/20"
  name        = "default-route-6e9e558a311d758b"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-70d163ddd9db90b1" {
  description = "Default local route to the subnetwork 10.15.128.0/22."
  dest_range  = "10.15.128.0/22"
  name        = "default-route-70d163ddd9db90b1"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-762c4d527b5fb59d" {
  description = "Default local route to the subnetwork 10.182.0.0/20."
  dest_range  = "10.182.0.0/20"
  name        = "default-route-762c4d527b5fb59d"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-822261d84a0008cc" {
  description = "Default local route to the subnetwork 10.174.0.0/20."
  dest_range  = "10.174.0.0/20"
  name        = "default-route-822261d84a0008cc"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-8c2a5ded2ab172a5" {
  description = "Default local route to the subnetwork 10.142.0.0/20."
  dest_range  = "10.142.0.0/20"
  name        = "default-route-8c2a5ded2ab172a5"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-8c59e1003c2aea9a" {
  description = "Default local route to the subnetwork 10.164.0.0/20."
  dest_range  = "10.164.0.0/20"
  name        = "default-route-8c59e1003c2aea9a"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-a605cfab1e883d97" {
  description = "Default local route to the subnetwork 10.160.0.0/20."
  dest_range  = "10.160.0.0/20"
  name        = "default-route-a605cfab1e883d97"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-aaa95f58880b4539" {
  description = "Default local route to the subnetwork 10.178.0.0/20."
  dest_range  = "10.178.0.0/20"
  name        = "default-route-aaa95f58880b4539"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-b30a3747864cb221" {
  description = "Default local route to the subnetwork 10.220.0.0/20."
  dest_range  = "10.220.0.0/20"
  name        = "default-route-b30a3747864cb221"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-b3944f94d84b21d3" {
  description = "Default local route to the subnetwork 10.210.0.0/20."
  dest_range  = "10.210.0.0/20"
  name        = "default-route-b3944f94d84b21d3"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-b436399618385a45" {
  description = "Default local route to the subnetwork 10.224.0.0/20."
  dest_range  = "10.224.0.0/20"
  name        = "default-route-b436399618385a45"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-b9544dd75c7bd845" {
  description = "Default local route to the subnetwork 10.186.0.0/20."
  dest_range  = "10.186.0.0/20"
  name        = "default-route-b9544dd75c7bd845"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-b9a758531c634389" {
  description = "Default local route to the subnetwork 10.138.0.0/20."
  dest_range  = "10.138.0.0/20"
  name        = "default-route-b9a758531c634389"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-b9fc956318858de8" {
  description = "Default local route to the subnetwork 10.208.0.0/20."
  dest_range  = "10.208.0.0/20"
  name        = "default-route-b9fc956318858de8"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-bb236044b4cb48b3" {
  description = "Default local route to the subnetwork 10.150.0.0/20."
  dest_range  = "10.150.0.0/20"
  name        = "default-route-bb236044b4cb48b3"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-bc22a360c153a1df" {
  description = "Default local route to the subnetwork 10.214.0.0/20."
  dest_range  = "10.214.0.0/20"
  name        = "default-route-bc22a360c153a1df"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-bc71975f66acf37b" {
  description = "Default local route to the subnetwork 10.198.0.0/20."
  dest_range  = "10.198.0.0/20"
  name        = "default-route-bc71975f66acf37b"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-c3ebc7e79ff59845" {
  description = "Default local route to the subnetwork 10.192.0.0/20."
  dest_range  = "10.192.0.0/20"
  name        = "default-route-c3ebc7e79ff59845"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-cbf0135711a362e9" {
  description = "Default local route to the subnetwork 10.146.0.0/20."
  dest_range  = "10.146.0.0/20"
  name        = "default-route-cbf0135711a362e9"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-cbfb5598385c147d" {
  description = "Default local route to the subnetwork 10.212.0.0/20."
  dest_range  = "10.212.0.0/20"
  name        = "default-route-cbfb5598385c147d"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-d4ed55e845390a86" {
  description = "Default local route to the subnetwork 10.218.0.0/20."
  dest_range  = "10.218.0.0/20"
  name        = "default-route-d4ed55e845390a86"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-d7e4946a6a99994a" {
  description = "Default local route to the subnetwork 10.168.0.0/20."
  dest_range  = "10.168.0.0/20"
  name        = "default-route-d7e4946a6a99994a"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-dcfaebc01d2cab7e" {
  description = "Default local route to the subnetwork 10.204.0.0/20."
  dest_range  = "10.204.0.0/20"
  name        = "default-route-dcfaebc01d2cab7e"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-def87b98ddb6c94e" {
  description = "Default local route to the subnetwork 10.200.0.0/20."
  dest_range  = "10.200.0.0/20"
  name        = "default-route-def87b98ddb6c94e"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-e39e7006eed9d206" {
  description = "Default local route to the subnetwork 10.170.0.0/20."
  dest_range  = "10.170.0.0/20"
  name        = "default-route-e39e7006eed9d206"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-e801f37bcfe7fae2" {
  description = "Default local route to the subnetwork 10.166.0.0/20."
  dest_range  = "10.166.0.0/20"
  name        = "default-route-e801f37bcfe7fae2"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-f38752e7d490cc13" {
  description = "Default local route to the subnetwork 10.196.0.0/20."
  dest_range  = "10.196.0.0/20"
  name        = "default-route-f38752e7d490cc13"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-f41f1cb86e6576df" {
  description = "Default local route to the subnetwork 10.132.0.0/20."
  dest_range  = "10.132.0.0/20"
  name        = "default-route-f41f1cb86e6576df"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-fe1136f42465b2b4" {
  description = "Default local route to the subnetwork 10.158.0.0/20."
  dest_range  = "10.158.0.0/20"
  name        = "default-route-fe1136f42465b2b4"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-ffc2d2f2c7ff388b" {
  description = "Default local route to the subnetwork 10.100.0.0/20."
  dest_range  = "10.100.0.0/20"
  name        = "default-route-ffc2d2f2c7ff388b"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}

resource "google_compute_route" "tfer--default-route-r-8e69a287829acb70" {
  description = "Default local route to the subnetwork 10.226.0.0/20."
  dest_range  = "10.226.0.0/20"
  name        = "default-route-r-8e69a287829acb70"
  network     = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  priority    = "0"
  project     = "cal-itp-data-infra"
}
