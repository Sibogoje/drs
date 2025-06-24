<?php
require_once 'connection.php';

try {
    // Create doctors table
    $createDoctorsTable = "
        CREATE TABLE IF NOT EXISTS doctors (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            specialty VARCHAR(255) NOT NULL,
            work_days JSON NOT NULL COMMENT 'Array of work days (1-7)',
            shift_start TIME NOT NULL,
            shift_end TIME NOT NULL,
            leave_days JSON DEFAULT NULL COMMENT 'Array of leave dates',
            off_days JSON DEFAULT NULL COMMENT 'Array of off dates',
            last_on_call_date DATE DEFAULT NULL,
            is_on_mandatory_rest BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ";
    
    // Create schedules table
    $createSchedulesTable = "
        CREATE TABLE IF NOT EXISTS schedules (
            id INT AUTO_INCREMENT PRIMARY KEY,
            doctor_id INT NOT NULL,
            schedule_date DATE NOT NULL,
            start_time TIME NOT NULL,
            end_time TIME NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
            UNIQUE KEY unique_schedule (doctor_id, schedule_date)
        )
    ";
    
    $pdo->exec($createDoctorsTable);
    $pdo->exec($createSchedulesTable);
    
    // Insert sample doctors
    $sampleDoctors = [
        [
            'name' => 'Dr. Smith',
            'specialty' => 'Emergency Medicine',
            'work_days' => json_encode([1, 2, 3, 4, 5]),
            'shift_start' => '08:00:00',
            'shift_end' => '17:00:00'
        ],
        [
            'name' => 'Dr. Johnson',
            'specialty' => 'Internal Medicine',
            'work_days' => json_encode([1, 2, 3, 4, 5]),
            'shift_start' => '08:00:00',
            'shift_end' => '17:00:00'
        ],
        [
            'name' => 'Dr. Williams',
            'specialty' => 'Surgery',
            'work_days' => json_encode([2, 3, 4, 5, 6]),
            'shift_start' => '07:00:00',
            'shift_end' => '18:00:00'
        ]
    ];
    
    $insertDoctor = "INSERT IGNORE INTO doctors (name, specialty, work_days, shift_start, shift_end, leave_days, off_days) 
                     VALUES (?, ?, ?, ?, ?, '[]', '[]')";
    $stmt = $pdo->prepare($insertDoctor);
    
    foreach ($sampleDoctors as $doctor) {
        $stmt->execute([
            $doctor['name'],
            $doctor['specialty'],
            $doctor['work_days'],
            $doctor['shift_start'],
            $doctor['shift_end']
        ]);
    }
    
    $db->sendResponse(null, 200, 'Database setup completed successfully');
    
} catch (PDOException $e) {
    $db->sendErrorResponse("Database setup failed: " . $e->getMessage(), 500);
}
?>
