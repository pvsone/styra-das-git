package rules

import data.dataset as restdatasource
import data.mygitdatasource as gitdatasource

default allow = false

allow {
  restdatasource.key == "foo"
}

allow {
  gitdatasource.foodata.key == "gitfoo"
}

allow {
  gitdatasource.bardata.key == "gitbar"
}
