# das-git

An example to demonstrate how to connect a Styra DAS Custom System to Git for both Rego policy and JSON data.

## Setup
Set environment variables for use in the `curl` commands in the steps below:
```bash
export STYRA_ORGANIZATION_ID="<TENANT>.styra.com"
export STYRA_TOKEN="<API_TOKEN>"
```

## Create a Git-backed System through the API

_Reference doc:_ https://docs.styra.com/v1/docs/policies/git-management/use-git-storage-systems/

### 1. Create a Styra Secret for your Git credentials
```bash
curl -X PUT \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/secrets/mygitsecret" \
  -d '{ "name": "pvsone", "secret": "<GIT-ACCESS-TOKEN>" }'
```
* Update the `name` and `secret` values as appropriate for your environment.
* The secret will be named `mygitsecret`.  You can provide any name value you prefer.

### 2. Create a Custom System with Git integration enabled
```bash
cat <<EOF > system.json
{
  "name": "mysystem",
  "type": "custom",
  "source_control": {
    "origin": {
      "url": "https://github.com/pvsone/das-git.git",
      "reference": "refs/heads/main",
      "credentials": "mygitsecret",
      "path": "mysystem/policy-code"
    }
  }
}
EOF
```
* Update the `url` and `path` (and any other) values as appropriate for your environment.
* The system will be named `mysystem`.  You can provide any name value you prefer.

```bash
curl \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/systems" \
  -d @system.json
```

### 3. (Optional) Update the default REST-based Data Source
For a Custom System type, Styra DAS creates a default REST-based Data Source named `dataset`, which can be updated via the Styra DAS API:
```bash
# get the system id for the created system, either from the JSON of the system create command, or from the DAS UI.
export STYRA_SYSTEM_ID=<mysystem-id-value>

curl -X PUT \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/data/systems/${STYRA_SYSTEM_ID}/dataset" \
  -d '{"key": "foo"}'
```

Styra DAS will begin to synchronize the Rego policy files into `mysystem`.  Within a minute or two, the following Git status will appear under the Status tab, and the `rules.rego` file contents will be updated appropriately
```json
{
  "code": "sync_successful",
  "files_synced": [
    "mysystem/policy-code/rules/rules.rego"
  ],
  "head_commit_sha": "ab5f9c708d96b53f1fd326dd4f50f6db7695ed41",
  "message": "Success",
  "repo_url": "https://github.com/pvsone/das-git.git",
  "timestamp": "2021-01-07T16:15:10.921358427Z"
}
```

### 4. (Optional) Create another REST-based Data Source
You can create as many Data Sources as you like.  REST-based Data Sources can be created via the UI or via the DAS API, and will be fully visible in the UI.
```bash
curl -X PUT \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/datasources/systems/${STYRA_SYSTEM_ID}/anotherds" \
  -d '{ "category": "rest", "type": "push" }'
```

Note that the Data Source name, e.g. `anotherds`, can also be a path-based value, e.g `path/to/mydatasource`, and if so, the Data Source will be shown in the DAS UI with the respective folder hierarchy.

Publish Data to the Data Source
```bash
curl -X PUT \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/data/systems/${STYRA_SYSTEM_ID}/anotherds" \
  -d '{ "baz": "qux", "foo": "bar" }'
```

Patch Data in the Data Source using [JSON Patch](http://jsonpatch.com)
```bash
curl -X PATCH \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json-patch+json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/data/systems/${STYRA_SYSTEM_ID}/anotherds" \
  -d '[
    { "op": "replace", "path": "/baz", "value": "boo" },
    { "op": "add", "path": "/hello", "value": ["world"] },
    { "op": "remove", "path": "/foo" }
  ]'
```

### 5. Create a Git-based Data Source

_Reference doc:_ https://docs.styra.com/v1/docs/policies/policy-authoring/datasources/supported-types/git/

```bash
cat <<EOF > datasource.json
{
  "category": "git/rego",
  "type": "pull",
  "url": "https://github.com/pvsone/das-git.git",
  "reference": "refs/heads/main",
  "credentials": "mygitsecret",
  "path": "mysystem/policy-data"
}
EOF

curl -X PUT \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/datasources/systems/${STYRA_SYSTEM_ID}/mygitdatasource" \
  -d @datasource.json
```
* The datasource will be named `mygitdatasource`.  You can provide any name value you prefer.

Check the Status of the Data Source via the API.  Look for a `status.code` value of `finished`.
```bash
curl \
  -H "Authorization: Bearer ${STYRA_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://${STYRA_ORGANIZATION_ID}/v1/datasources/systems/${STYRA_SYSTEM_ID}/mygitdatasource" | jq .

{
  "request_id": "9930d311-4448-40de-a6cf-caf74934aae7",
  "result": {
    "category": "git/rego",
    "credentials": "mygitsecret",
    "id": "systems/b188839ee58249528557d70e47fb17d4/mygitdatasource",
    "metadata": {
      "created_at": "2021-01-07T18:52:31.129260836Z",
      "created_by": "psullivan@styra.com",
      "created_through": "access/sullivan",
      "last_modified_at": "2021-01-07T18:52:31.129260836Z",
      "last_modified_by": "psullivan@styra.com",
      "last_modified_through": "access/sullivan"
    },
    "path": "mysystem/policy-data",
    "reference": "refs/heads/main",
    "status": {
      "code": "finished",
      "message": "",
      "timestamp": "2021-01-07T19:01:55Z"
    },
    "type": "pull",
    "url": "https://github.com/pvsone/das-git.git"
  }
}
```

Check the Data Source in the Styra DAS UI.  A new Data Source with the name `mygitdatasource` will appear in the UI, with the following contents:
```json
{
  "_data": {
    "bardata": {
      "data.json": {}
    },
    "foodata": {
      "data.json": {}
    }
  },
  "_packages": {},
  "_signatures": null,
  "bardata": {
    "key": "gitbar"
  },
  "foodata": {
    "key": "gitfoo"
  }
}
```

The `_data`, `_packages` and `_signatures` fields are special metadata fields maintained by Styra DAS.  The raw JSON data (e.g. `bardata` and `foodata`) will be visible.

### 6. Import the Data Sources into the Policy
The `mysystem/policy-code/rules/rules.rego` file within this repository contains example rules that demonstrate importing data from the Data Sources (both Rest-based and Git-based), and using the data within policy rules
```rego
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
```
