/*  This module assign membership for a group of users 
to a group
*/
# BACKEND SECTION - this section should be in all module code
terraform {
 backend "remote"{}
#    hostname="app.terraform.io"
#    organization="SRE-sandbox"
#    workspaces {name = "gitlab-groupmembers-module-sandbox"}
#  }
}
# PROVIDER SECTION - this section is provider specific but should be in all module code
provider "gitlab" {
   token = var.modinput_token
   version = "~> 2.5"
}
locals {
    user-member = csvdecode(file("${var.modinput_emails}"))
}
data "gitlab_user" "arcules_user" {
    for_each = {for inst in local.user-member:inst.emails=>inst}
    email = each.value.emails
}
locals {
    userid = [for key, u in data.gitlab_user.company_user: {
       user-key = key
       user-id = u.id
    }]
    groupids = [for key, inst in var.modinput_groupid: {
       group-key = key
       group-id = inst
    }]
    membership = [
      for pair in setproduct(local.userid,local.groupids): {
         user = pair[0].user-id
         group = pair[1].group-id
      }]
}
output "local-userid" {
    value = local.userid
}
output "local-projects" {
    value = local.groupids
}
output "membershiplist" {
    value = local.membership
}
resource "gitlab_group_membership" "togroups" {
   for_each = {for sample in local.membership: "${sample.user}.${sample.group}" => sample}
   user_id = each.value.user
   access_level = var.modinput_role
   group_id = each.value.group
}
