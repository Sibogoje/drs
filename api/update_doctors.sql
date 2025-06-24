-- Remove existing sample doctors and their schedules
DELETE FROM schedules WHERE doctor_id IN (
    SELECT id FROM doctors WHERE name IN ('Dr. Smith', 'Dr. Johnson', 'Dr. Williams')
);

DELETE FROM doctors WHERE name IN ('Dr. Smith', 'Dr. Johnson', 'Dr. Williams');

-- Add new doctors
INSERT INTO doctors (name, specialty, work_days, shift_start, shift_end, leave_days, off_days) VALUES
('Dr Kekezwa', 'General Medicine', '[1,2,3,4,5]', '08:00:00', '17:00:00', '[]', '[]'),
('Dr Udeagha', 'Emergency Medicine', '[1,2,3,4,5]', '08:00:00', '17:00:00', '[]', '[]'),
('Dr Fundama', 'Surgery', '[1,2,3,4,5]', '07:00:00', '18:00:00', '[]', '[]'),
('Dr Mgwambani', 'Pediatrics', '[1,2,3,4,5]', '08:00:00', '17:00:00', '[]', '[]'),
('Dr Ngwenya', 'Cardiology', '[1,2,3,4,5]', '08:00:00', '17:00:00', '[]', '[]'),
('Dr Anjum', 'Anesthesiology', '[1,2,3,4,5,6]', '07:00:00', '19:00:00', '[]', '[]'),
('Dr Ngcobo', 'Orthopedics', '[1,2,3,4,5]', '08:00:00', '17:00:00', '[]', '[]'),
('Dr Ravele', 'Neurology', '[1,2,3,4,5]', '08:00:00', '17:00:00', '[]', '[]');

-- Reset auto increment counter
ALTER TABLE doctors AUTO_INCREMENT = 1;

-- Verify the new doctors
SELECT id, name, specialty, work_days, shift_start, shift_end FROM doctors ORDER BY name;
