package terraform.analysis

import input as tfplan

# Rule 1: Enforce mandatory tags
deny[msg] {
  resource := tfplan.resource_changes[_]
  action := resource.change.actions[count(resource.change.actions) - 1]
  array_contains(["create", "update"], action)
  resource.type == "aws_instance"
  not resource.change.after.tags.Name
  msg := sprintf("Resource '%v' missing mandatory tag 'Name'", [resource.address])
}

# Rule 2: Restrict instance types (Cost Control)
allowed_types = ["t2.micro", "t3.small", "t3.medium"]

deny[msg] {
  resource := tfplan.resource_changes[_]
  action := resource.change.actions[count(resource.change.actions) - 1]
  array_contains(["create", "update"], action)
  resource.type == "aws_instance"
  not array_contains(allowed_types, resource.change.after.instance_type)
  msg := sprintf("Instance type '%v' is not allowed for resource '%v'. Allowed: %v", [resource.change.after.instance_type, resource.address, allowed_types])
}

array_contains(arr, elem) {
  arr[_] = elem
}
