package  
{  //done exept for enemies and breathing related coed
	import net.flashpunk.Entity;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.FP;
	
	/**
	 * ...
	 * @author Jordan Magnuson
	 */
	public class LightTail extends Entity
	{
		public static var moving:Boolean = false;
		
		public static const MIN_SPEED:Number = 20;
		//public static const MAX_SPEED:Number = 150;
		//public static const ROTATIONS_TILL_CHANGE_SPEED:int = 1;
		public static const SPEED_CHANGE_RATE:Number = 2.5;
		
		public static var speed:Number = MIN_SPEED;
		public static var angle:Number = 0;
		
		// Number of rotations the light tail has made since game start
		public static var rotations:Number = 0;
		
		// Player graphic
		[Embed(source='../assets/light_tail.png')] private const S_LIGHT_TAIL:Class;
		public var image:Image = new Image(S_LIGHT_TAIL);			
		
		public function LightTail() 
		{
			type = 'light_tail';
			graphic = image;
			image.smooth = true;
			image.angle = 90;
			layer = 10;
			
			// Initial position
			this.x = FP.screen.width / 2;
			this.y = FP.screen.height / 2;	
			speed = MIN_SPEED;
			angle = 90;
			//visible = false;
			
			// Initialize image, hitbox
			image.originX = image.width / 2;
			image.originY = image.height / 2;
			image.x = -image.originX;
			image.y = -image.originY;		
			setHitbox(image.width, image.height, image.originX, image.originY);	
		}
		
		override public function update():void
		{
			if (moving)
				rotate();
			super.update();
			//trace('lt angle: ' + angle);
		}
		
		/**
		 * Changes the rotation speed of the light tail to the given number,
		 * and updates all enemies to match the new speed.
		 * @param	speed
		 */
		public static function changeRotationSpeed(speed:Number):void
		{
			LightTail.speed = speed;
			trace('speed: ' + speed);
			var enemyList:Array = [];
			FP.world.getClass(Enemy, enemyList);
			for each (var e:Enemy in enemyList)
				e.speedMatchLightTail();			
		}
		
		public function rotate():void
		{
			angle += FP.elapsed * speed;
			if (angle > 360)	// Full rotation
			{
				trace('full rotation');
				rotations++;
				trace('rotations: ' + rotations);
				changeRotationSpeed(speed + (SPEED_CHANGE_RATE / rotations));
				GameWorld.enemyController.changeReleaseRate(EnemyController.releaseRate - (EnemyController.RELEASE_RATE_CHANGE / rotations));
				angle = angle - 360;
			}
			image.angle = angle;		
			if (SafeZone.breathing)
				image.scale = SafeZone.breathe.value;
		}
		
	}

}