<?php
require_once 'connection.php';

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        getDoctors();
        break;
    case 'POST':
        createDoctor($input);
        break;
    case 'PUT':
        updateDoctor($input);
        break;
    case 'DELETE':
        deleteDoctor($input);
        break;
    default:
        $db->sendErrorResponse('Method not allowed', 405);
}

function getDoctors() {
    global $pdo, $db;
    
    try {
        $doctorId = $_GET['id'] ?? null;
        
        if ($doctorId) {
            $stmt = $pdo->prepare("SELECT * FROM doctors WHERE id = ?");
            $stmt->execute([$doctorId]);
            $doctor = $stmt->fetch();
            
            if ($doctor) {
                $doctor['work_days'] = json_decode($doctor['work_days']);
                $doctor['leave_days'] = json_decode($doctor['leave_days']) ?: [];
                $doctor['off_days'] = json_decode($doctor['off_days']) ?: [];
                $db->sendResponse($doctor);
            } else {
                $db->sendErrorResponse('Doctor not found', 404);
            }
        } else {
            $stmt = $pdo->query("SELECT * FROM doctors ORDER BY name");
            $doctors = $stmt->fetchAll();
            
            foreach ($doctors as &$doctor) {
                $doctor['work_days'] = json_decode($doctor['work_days']);
                $doctor['leave_days'] = json_decode($doctor['leave_days']) ?: [];
                $doctor['off_days'] = json_decode($doctor['off_days']) ?: [];
            }
            
            $db->sendResponse($doctors);
        }
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error fetching doctors: " . $e->getMessage(), 500);
    }
}

function createDoctor($input) {
    global $pdo, $db;
    
    $required = ['name', 'specialty', 'work_days', 'shift_start', 'shift_end'];
    $missing = validateRequired($input, $required);
    
    if (!empty($missing)) {
        $db->sendErrorResponse('Missing required fields: ' . implode(', ', $missing), 400);
    }
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO doctors (name, specialty, work_days, shift_start, shift_end, leave_days, off_days) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            sanitizeInput($input['name']),
            sanitizeInput($input['specialty']),
            json_encode($input['work_days']),
            $input['shift_start'],
            $input['shift_end'],
            json_encode($input['leave_days'] ?? []),
            json_encode($input['off_days'] ?? [])
        ]);
        
        $doctorId = $pdo->lastInsertId();
        $db->sendResponse(['id' => $doctorId], 201, 'Doctor created successfully');
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error creating doctor: " . $e->getMessage(), 500);
    }
}

function updateDoctor($input) {
    global $pdo, $db;
    
    if (!isset($input['id'])) {
        $db->sendErrorResponse('Doctor ID is required', 400);
    }
    
    try {
        $updateFields = [];
        $params = [];
        
        $allowedFields = ['name', 'specialty', 'work_days', 'shift_start', 'shift_end', 
                         'leave_days', 'off_days', 'last_on_call_date', 'is_on_mandatory_rest'];
        
        foreach ($allowedFields as $field) {
            if (isset($input[$field])) {
                if (in_array($field, ['work_days', 'leave_days', 'off_days'])) {
                    $updateFields[] = "$field = ?";
                    $params[] = json_encode($input[$field]);
                } else {
                    $updateFields[] = "$field = ?";
                    $params[] = $field === 'is_on_mandatory_rest' ? (bool)$input[$field] : $input[$field];
                }
            }
        }
        
        if (empty($updateFields)) {
            $db->sendErrorResponse('No fields to update', 400);
        }
        
        $params[] = $input['id'];
        $sql = "UPDATE doctors SET " . implode(', ', $updateFields) . " WHERE id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        
        if ($stmt->rowCount() > 0) {
            $db->sendResponse(null, 200, 'Doctor updated successfully');
        } else {
            $db->sendErrorResponse('Doctor not found or no changes made', 404);
        }
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error updating doctor: " . $e->getMessage(), 500);
    }
}

function deleteDoctor($input) {
    global $pdo, $db;
    
    if (!isset($input['id'])) {
        $db->sendErrorResponse('Doctor ID is required', 400);
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM doctors WHERE id = ?");
        $stmt->execute([$input['id']]);
        
        if ($stmt->rowCount() > 0) {
            $db->sendResponse(null, 200, 'Doctor deleted successfully');
        } else {
            $db->sendErrorResponse('Doctor not found', 404);
        }
        
    } catch (PDOException $e) {
        $db->sendErrorResponse("Error deleting doctor: " . $e->getMessage(), 500);
    }
}
?>
