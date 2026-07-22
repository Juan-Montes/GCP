package main

import rego.v1

# =============================================================================
#  Política: solo se permiten tipos de máquina económicos (disciplina de costo).
# =============================================================================
allowed_machine_types := {"e2-micro", "e2-small", "e2-medium"}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_compute_instance_template"
	mt := rc.change.after.machine_type
	not mt in allowed_machine_types
	msg := sprintf("Plantilla '%s' usa machine_type '%s', fuera de la lista permitida %v.", [rc.address, mt, allowed_machine_types])
}
