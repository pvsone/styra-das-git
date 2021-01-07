package rules

import data.dataset as restdatasource

default allow = false

allow {
  restdatasource.key == "foo"
}
