CREATE TABLE personal_audit(
    audit_date TIMESTAMP,
    audit_user VARCHAR(40),
    audit_action ENUM('update','delete'),
    ID_PERSONA VARCHAR(7)
);

CREATE TRIGGER tg_cemabePersonal_BD
BEFORE DELETE ON CEMABE_PERSONAL
FOR EACH ROW
INSERT INTO personal_audit(audit_user,audit_action,ID_PERSONA) 
VALUES(CURRENT_USER(),'delete',OLD.ID_PERSONA);