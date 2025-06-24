<?php
require_once 'connection.php';

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        getSchedules();
        break;
    case 'POST':
        createSchedule($input);
        break;
    case 'PUT':
        updateSchedule($input);
        break;
    case 'DELETE':
        deleteSchedule($input);
        break;
    default:
        $db->sendErrorResponse('Method not allowed', 405);
}

function getSchedules() {
    global $pdo, $db;
    
    try {
        $date = $_GET['date'] ?? null;
        $doctorId = $_GET['doctor_id'] ?? null;
        
        $sql = "
            SELECT s.*, d.name as doctor_name, d.specialty 
            FROM schedules s 
            JOIN doctors d ON s.doctor_id = d.id
        ";
        $params = [];
        $conditions = [];
        
        if ($date) {
            $conditions[] = "s.schedule_date = ?";
            $params[] = $date;
        }
        
        if ($doctorId) {
            $conditions[] = "s.doctor_id = ?";
            $params[] = $doctorId;
        }
        
        if (!empty($conditions)) {
            $sql .= " WHERE " . implode(' AND ', $conditions);
        }
        
        $sql .= " ORDER BY s.schedule_date, s.start_time";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $schedules = $stmt->fetchAll();
        
        $db->sendResponse($schedules);
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error fetching schedules: " . $e->getMessage(), 500);
    }
}

function createSchedule($input) {
    global $pdo, $db;
    
    $required = ['doctor_id', 'schedule_date', 'start_time', 'end_time'];
    $missing = validateRequired($input, $required);
    
    if (!empty($missing)) {
        $db->sendErrorResponse('Missing required fields: ' . implode(', ', $missing), 400);
    }
    
    try {
        // Check if doctor exists
        $stmt = $pdo->prepare("SELECT id FROM doctors WHERE id = ?");
        $stmt->execute([$input['doctor_id']]);
        if (!$stmt->fetch()) {
            $db->sendErrorResponse('Doctor not found', 404);
        }
        
        // Check for existing schedule
        $stmt = $pdo->prepare("SELECT id FROM schedules WHERE doctor_id = ? AND schedule_date = ?");
        $stmt->execute([$input['doctor_id'], $input['schedule_date']]);
        if ($stmt->fetch()) {
            $db->sendErrorResponse('Schedule already exists for this doctor on this date', 409);
        }
        
        $stmt = $pdo->prepare("
            INSERT INTO schedules (doctor_id, schedule_date, start_time, end_time) 
            VALUES (?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $input['doctor_id'],
            $input['schedule_date'],
            $input['start_time'],
            $input['end_time']
        ]);
        
        $scheduleId = $pdo->lastInsertId();
        
        // Update doctor's last on call date and mandatory rest status
        $updateDoctor = $pdo->prepare("
            UPDATE doctors 
            SET last_on_call_date = ?, is_on_mandatory_rest = TRUE 
            WHERE id = ?
        ");
        $updateDoctor->execute([$input['schedule_date'], $input['doctor_id']]);
        
        $db->sendResponse(['id' => $scheduleId], 201, 'Schedule created successfully');
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error creating schedule: " . $e->getMessage(), 500);
    }
}

function updateSchedule($input) {
    global $pdo, $db;
    
    if (!isset($input['id'])) {
        $db->sendErrorResponse('Schedule ID is required', 400);
    }
    
    try {
        $updateFields = [];
        $params = [];
        
        $allowedFields = ['doctor_id', 'schedule_date', 'start_time', 'end_time'];
        
        foreach ($allowedFields as $field) {
            if (isset($input[$field])) {
                $updateFields[] = "$field = ?";
                $params[] = $input[$field];
            }
        }
        
        if (empty($updateFields)) {
            $db->sendErrorResponse('No fields to update', 400);
        }
        
        $params[] = $input['id'];
        $sql = "UPDATE schedules SET " . implode(', ', $updateFields) . " WHERE id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        
        if ($stmt->rowCount() > 0) {
            $db->sendResponse(null, 200, 'Schedule updated successfully');
        } else {
            $db->sendErrorResponse('Schedule not found or no changes made', 404);
        }
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error updating schedule: " . $e->getMessage(), 500);
    }
}

function deleteSchedule($input) {
    global $pdo, $db;
    
    if (!isset($input['id'])) {
        $db->sendErrorResponse('Schedule ID is required', 400);
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM schedules WHERE id = ?");
        $stmt->execute([$input['id']]);
        
        if ($stmt->rowCount() > 0) {
            $db->sendResponse(null, 200, 'Schedule deleted successfully');
        } else {
            $db->sendErrorResponse('Schedule not found', 404);
        }
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error deleting schedule: " . $e->getMessage(), 500);
    }
}
?>
