package main

import rego.v1

# =============================================================================
#  Política: los recursos etiquetables deben llevar labels de trazabilidad.
# =============================================================================
required_labels := {"entorno", "nivel"}

labelable := {"google_compute_instance_template", "google_storage_bucket"}

# Devuelve los labels del recurso, o {} si no tiene (evita errores con null).
after_labels(rc) := l if {
	l := rc.change.after.labels
	l != null
} else := {}

deny contains msg if {
	some rc in input.resource_changes
	rc.type in labelable
	some required in required_labels
	not after_labels(rc)[required]
	msg := sprintf("%s '%s' no tiene el label requerido '%s'.", [rc.type, rc.address, required])
}
