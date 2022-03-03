event_inherited();

LastAngle = 0; 
rotations = 0;
image_alpha = 0;

function speedMatchLightTail(){
	return (((oLightTail.tailSpeed * pi / 180) * (point_distance(x,y,centerX,centerY)))/ room_speed);
} 

function updateRotations(){
	currentAngle = pointDirection(centerX, centerY, x, y);
	if (currentAngle < 0)
		currentAngle += 360;
	if (currentAngle < LastAngle && currentAngle > oEnemyController.releaseAngle)
		destroy();	
	LastAngle = currentAngle;			
}

function inDarkness(){
	angle = pointDirection(centerX, centerY, x, y);
	if (angle < 0)
		angle += 360;			
	if (abs(oLightTail.image_angle - angle) > 88 && abs(oLightTail.image_angle - angle) < 270)
		return true;
	else
		return false;
}	
		
function destroy(){
	instance_destroy();			
}