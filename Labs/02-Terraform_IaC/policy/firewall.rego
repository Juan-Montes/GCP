package main

import rego.v1

# =============================================================================
#  Política: ninguna regla de firewall puede exponer 0.0.0.0/0.
#  (La firma de gobernanza de red que arrastramos desde el Nivel 01.)
# =============================================================================
deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_compute_firewall"
	some rango in rc.change.after.source_ranges
	rango == "0.0.0.0/0"
	msg := sprintf("Firewall '%s' expone 0.0.0.0/0 — prohibido por política.", [rc.address])
}
