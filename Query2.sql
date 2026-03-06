-- Carl Everman

-- 1
CREATE TABLE DischargeLog(
logID INT AUTO_INCREMENT NOT NULL,
appointmentID INT NOT NULL,
patientID VARCHAR(50) NOT NULL,
dischargeDate DATE,
FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID),
FOREIGN KEY (patientID) REFERENCES Patient(patientID),
PRIMARY KEY (logID)
);

CREATE TABLE Doctor (
doctorID VARCHAR(50) NOT NULL,
Fname VARCHAR(20),
Lname VARCHAR(20),
Speciality VARCHAR(50),
Phone VARCHAR(20),
PRIMARY KEY (doctorID)
);
DROP TABLE Doctor;

CREATE TABLE Patient (
patientID VARCHAR(50) NOT NULL,
Fname VARCHAR(50),
Lname VARCHAR(50),
Age INT,
Email VARCHAR(50),
PRIMARY KEY (patientID)
);
DROP TABLE Patient;
CREATE TABLE Appointment (
appointmentID INT AUTO_INCREMENT NOT NULL,
patientID VARCHAR (50) NOT NULL,
doctorID VARCHAR (50) NOT NULL,
FOREIGN KEY (patientID) REFERENCES Patient(patientID),
FOREIGN KEY (doctorID) REFERENCES Doctor(doctorID),
appointmentDate DATE,
durationInDays INT,
dischargeDate DATE,
PRIMARY KEY (appointmentID)
);
DROP TABLE Appointment;

INSERT INTO Doctor VALUES ('D001','Erik','Svensson','Cardiology','08-1234567');
INSERT INTO Doctor VALUES ('D002','Sara','Lindqvist','Neurology','08-9876543');
INSERT INTO Doctor VALUES ('D003','Johan','Berg','Orthopedics','08-1122334');
INSERT INTO Patient VALUES ('P001','Anna','Olsson',34,'anna@mail.com');
INSERT INTO Patient VALUES ('P002','Lars','Karlsson',52,'lars@mail.com');
INSERT INTO Patient VALUES ('P003','Maria','Holm',29,'maria@mail.com');
INSERT INTO Patient VALUES ('P004','Mikael','Strand',41,'mikael@mail.com');
INSERT INTO Patient VALUES ('P005','Karin','Lund',67,'karin@mail.com');
INSERT INTO Appointment VALUES (1,'P001','D001','2023-01-10',5,'2023-01-15');
INSERT INTO Appointment VALUES (2,'P002','D002','2023-02-01',10,'2023-02-12');
INSERT INTO Appointment VALUES (3,'P003','D001','2023-03-05',7,'2023-03-13');
INSERT INTO Appointment VALUES (4,'P001','D003','2023-04-10',14,'2023-04-25');
INSERT INTO Appointment VALUES (5,'P002','D001','2023-05-01',5,NULL);
INSERT INTO Appointment VALUES (6,'P004','D002','2023-06-15',8,NULL);
INSERT INTO Appointment VALUES (7,'P003','D003','2023-07-20',3,NULL);
INSERT INTO Appointment VALUES (8,'P005','D001','2022-12-01',10,'2022-12-08');

-- 2
SELECT 
	p.patientID,
    p.Fname,
    p.Lname,
    0 AS numOfAppointments
FROM Patient p
WHERE p.patientID NOT IN (
	SELECT patientID FROM Appointment
    );
    
-- 3
SELECT 
	d.doctorID,
    d.Fname,
    d.Lname,
    AVG(DATEDIFF(a.dischargeDate, a.appointmentDate)) AS AverageAppointmentTime
FROM Doctor d
JOIN Appointment a on d.doctorID = a.doctorID
WHERE a.dischargeDate IS NOT NULL
GROUP BY d.doctorID, d.Fname;

-- 4
CREATE OR REPLACE VIEW currentPatients AS
SELECT
	a.appointmentID,
	p.Fname, 
    p.Lname,
    a.appointmentDate,
    DATE_ADD(a.appointmentDate, INTERVAL a.durationInDays DAY) AS ExpectedDischarge
FROM Patient p
JOIN Appointment a ON p.patientID = a.patientID
WHERE a.dischargeDate IS NULL; 
SELECT * FROM currentPatients;


-- 5
DELIMITER //

CREATE TRIGGER logDischarge
AFTER UPDATE ON Appointment
FOR EACH ROW
BEGIN
	IF OLD.dischargeDate is NULL AND NEW.dischargeDate IS NOT NULL THEN
		INSERT INTO DischargeLog (appointmentID, patientID, dischargeDate)
		VALUES (NEW.appointmentID, NEW.patientID, NEW.dischargeDate);
    END IF;
END //

DELIMITER ;

UPDATE Appointment
SET dischargeDate = '2026-03-06'
WHERE appointmentID = 5;

-- Then check the log
SELECT * FROM DischargeLog;

-- 6
DELIMITER //

CREATE PROCEDURE BookAppointment(
	IN p_patientID VARCHAR(50),
    IN p_doctorID VARCHAR(50),
    IN p_appointmentDate DATE
    )
BEGIN
	DECLARE activeAppointments INT;
    
    SELECT COUNT(*) INTO activeAppointments
    FROM Appointment 
    WHERE doctorID = p_doctorID
    AND dischargeDate IS NULL;
	
    IF activeAppointments > 0 THEN
		SELECT 'Doctor not available' AS Message;
    ELSE
		INSERT INTO Appointment(patientID, doctorID, appointmentDate, durationInDays, dischargeDate)
        VALUES (p_patientID, p_doctorID, p_appointmentDate, NULL, NULL);
        SELECT 'Patient admitted' AS Message;
	END IF;
END //

DELIMITER ;
DROP PROCEDURE BookAppointment;
CALL BookAppointment('P003', 'D001', '2026-03-06');

-- 7

SELECT 
	p.patientID,
    CONCAT(p.Fname, ' ', p.Lname) AS name_,
    a.appointmentID,
    a.doctorID
FROM Patient p
LEFT JOIN Appointment a ON p.patientID = a.patientID
ORDER BY a.appointmentID DESC;

-- 8
SELECT
	CONCAT(p.FName, ' ', p.Lname) AS name_,
    d.Speciality,
    DATE_ADD(a.appointmentDate, INTERVAL a.durationInDays DAY) AS expectedDischarge
FROM Patient p
JOIN Appointment a ON p.patientID = a.patientID
JOIN Doctor d ON a.doctorID = a.doctorID
WHERE dischargeDate IS NULL
ORDER BY expectedDischarge DESC;

-- 9
SELECT 
	appointmentID,
    patientName,
    daysOverdue,
    daysOVerdue * 150 AS totalAmount
FROM(
    SELECT
    a.appointmentID,
    CONCAT(p.Fname, ' ', p.Lname) AS patientName,
    DATEDIFF(a.dischargeDate, a.appointmentDate)-a.durationInDays AS daysOverdue
FROM Appointment a
JOIN Patient p ON p.patientID = a.patientID
WHERE a.dischargeDate IS NOT NULL
)
AS sub
WHERE DaysOverdue > 0;

SELECT * FROM Appointment;