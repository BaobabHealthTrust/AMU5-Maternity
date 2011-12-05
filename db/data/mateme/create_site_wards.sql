INSERT INTO global_property (property, property_value, description) VALUES ("statistics.show_encounter_types", "REGISTRATION,OBSERVATIONS,DIAGNOSIS,UPDATE OUTCOME,REFER PATIENT OUT?", "Maternity Encounter Types") ON DUPLICATE KEY UPDATE property = "statistics.show_encounter_types";

DELETE FROM global_property WHERE property = "facility.login_wards";

INSERT INTO global_property (property, property_value, description) VALUES ("facility.login_wards", "Ante-Natal Ward,Labour Ward,Post-Natal Ward,Gynaecology Ward,Post-Natal Ward (Low Risk),Post-Natal Ward (High Risk)", "") ON DUPLICATE KEY UPDATE property = "facility.login_wards";

DELETE FROM global_property WHERE property = "facility.name";

INSERT INTO global_property (property, property_value, description) VALUES ("facility.name", "KAMUZU CENTRAL HOSPITAL", "Current Facility Name") ON DUPLICATE KEY UPDATE property = "facility.name";

INSERT INTO location (name, description, creator, date_created, retired, uuid) VALUES ("Ante-Natal Ward", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Bwaila Maternity Unit", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Labour Ward", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Post-Natal Ward", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Gynaecology Ward", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Post-Natal Ward (Low Risk)", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Post-Natal Ward (High Risk)", "Workstation Location", 1, now(), 0, (SELECT UUID())), ("Kamuzu Central Hospital", "Central Hospital", 1, now(), 0, (SELECT UUID())); 

INSERT INTO location_tag_map (location_id, location_tag_id) VALUES 
((SELECT location_id FROM location WHERE name = "Ante-Natal Ward"), (SELECT location_tag_id FROM location_tag WHERE name = "Workstation Location")),
((SELECT location_id FROM location WHERE name = "Labour Ward"), (SELECT location_tag_id FROM location_tag WHERE name = "Workstation Location")),
((SELECT location_id FROM location WHERE name = "Post-Natal Ward"), (SELECT location_tag_id FROM location_tag WHERE name = "Workstation Location")),
((SELECT location_id FROM location WHERE name = "Gynaecology Ward"), (SELECT location_tag_id FROM location_tag WHERE name = "Workstation Location")),
((SELECT location_id FROM location WHERE name = "Post-Natal Ward (Low Risk)"), (SELECT location_tag_id FROM location_tag WHERE name = "Workstation Location")),
((SELECT location_id FROM location WHERE name = "Post-Natal Ward (High Risk)"), (SELECT location_tag_id FROM location_tag WHERE name = "Workstation Location"))
