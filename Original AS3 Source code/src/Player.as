package  
{
	import net.flashpunk.Entity;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.FP;
	import net.flashpunk.Sfx;
	import net.flashpunk.tweens.misc.Alarm;
	import net.flashpunk.tweens.misc.NumTween;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.utils.Draw;
	
	/**
	 * ...
	 * @author Jordan Magnuson
	 */
	public class Player extends PolarMover
	{
		/**
		 * Constants.	Block done, is macros best way?
		 */
		public static const RADIUS_ORIG:Number = 8;
		public const MAX_SPEED:Number = 60;
		public const MAX_LINEAR_SPEED:Number = 35;
		public const GRAV:Number = 100;
		public const ACCEL:Number = 200;
		public const STUN_TIME:Number = 0.5;	// Seconds player can't move after being hit by enemy.
		public const STUN_COLOR:uint = Colors.RED;
		public const ENEMY_MOVE_DIST:Number = 20;	// Distance player moves when hits enemy.
		
		/**
		 * Movement properties.	Block done
		 */
		public var g:Number = 0;
		public var accel:Number = 0;
		public var accelCurrent:Number = 0;  
		public var speed:Number = 0;		
		
		/**
		 * Breathing	Block done
		 */
		public static var breatheAlarm:Alarm;
		public static var breathe:NumTween;
		public static var breathing:Boolean = true;		
		
		/**
		 * Other properties.     Block implemented do we need to make radius variable how to overwrite properly             
		 */
		public static var color:uint = Colors.WHITE;	// Color changes from white to black depending on where player is in LightTail.		
		public static var radius:Number = RADIUS_ORIG;
		public static var stunAlarm:Alarm;
		public static var canMove:Boolean = true;	// Whether the player input makes a difference.
		public static var frozen:Boolean = true; 	// Whether the player is totally frozen (no grav, etc.)
		
		/**
		 * Image.	needs work
		 */
		public var image:Image = Image.createCircle(9, Colors.WHITE);
		[Embed(source = '../assets/arrow.png')] private const ARROW:Class;
		public var arrowImage:Image = new Image(ARROW);		
		
		public function Player(x:Number = 0, y:Number = 0) 
		{
			type = 'player';
			//graphic = image;
			layer = 0;
			
			// Initial position
			this.x = FP.screen.width / 2;
			this.y = FP.screen.height / 2 + SafeZone.outerRadius - (SafeZone.outerRadius - SafeZone.innerRadius) / 2;			
			canMove = true;
			speed = 0;
			
			
			// Stun alarm
			stunAlarm = new Alarm(STUN_TIME, restoreMovement);
			addTween(stunAlarm);
			
			// Initialize image, hitbox
			//image.originX = image.width / 2;
			//image.originY = image.height / 2;
			//image.x = -image.originX;
			//image.y = -image.originY;		
			width = height = 2 * RADIUS_ORIG;
			setHitbox(width, height, x + halfWidth, y + halfHeight);	
			
			arrowImage.originX = arrowImage.width / 2;
			arrowImage.originY = arrowImage.height / 2;
			arrowImage.x = -arrowImage.originX;
			arrowImage.y = -arrowImage.originY;		
			//setHitbox(arrowImage.width, arrowImage.height, arrowImage.originX, arrowImage.originY);			
			
			// Define input     //done with input block
			Input.define("R", Key.RIGHT);
			Input.define("L", Key.LEFT);		
			Input.define("RESIST", Key.SPACE);
			
			// Breathe
			breatheIn();
		}
		
		override public function update():void 
		{
			if (breathing)
				breathe.active = true;
			else
				breathe.active = false;			
			updateColor();
			accelMovement();
			checkCollisions();
			checkSafeZone();	
			animate();
			if (Input.pressed("RESIST") || Input.mousePressed)
			{
				arrowImage.alpha -= .01;			
			}					
			//if (Input.RESIST") || Input.mouseUp)
				//changedAlpha = false;
			super.update();	
		}
		
		override public function render():void
		{
			// Render the arrow
			if ((Input.check("RESIST") || Input.mouseDown) && !frozen)
			{
				if (inDarkness())
				{
					arrowImage.color = Colors.WHITE;
					arrowImage.angle = 180;
					Draw.graphic(arrowImage, x, y + image.height);
				}
				else
				{
					arrowImage.color = Colors.BLACK;
					arrowImage.angle = 0;
					Draw.graphic(arrowImage, x, y - image.height);
				}
			}
			
			//Render the player
			Draw.circlePlus(x, y, radius, color, 1);
			
			//super.render();
		}
		
		public function animate():void
		{
			radius = RADIUS_ORIG * breathe.value;
			//width = height = radius * 2;
			//trace(width);
		}
		
		public function accelMovement():void
		{
			if (!frozen)
			{
				gravity();
				if (canMove) 
					acceleration();
				move(speed * FP.elapsed, pointDirection(x, y, FP.screen.width / 2, FP.screen.height / 2));	
			}			
		}
		
		/**
		 * Alternative movement with no acceleration... NOT BEING USED
		 */
		public function linearMovement():void
		{
			if (speed < MAX_LINEAR_SPEED)
				speed += 0.05;
			if (!frozen)
			{
				if (inDarkness())
				{
					if (canMove)
					{
						if (Input.check("RESIST") || Input.mouseDown)
							move(speed * FP.elapsed, pointDirection(FP.screen.width / 2, FP.screen.height / 2, x, y));
						else
							move(speed * FP.elapsed, pointDirection(x, y, FP.screen.width / 2, FP.screen.height / 2));	
					}
					else
						move(speed * FP.elapsed, pointDirection(x, y, FP.screen.width / 2, FP.screen.height / 2));
				}
				else 
				{
					if (canMove)
					{
						if (Input.check("RESIST") || Input.mouseDown)
							move(speed * FP.elapsed, pointDirection(x, y, FP.screen.width / 2, FP.screen.height / 2));
						else
							move(speed * FP.elapsed, pointDirection(FP.screen.width / 2, FP.screen.height / 2, x, y));	
					}
				}
			}
		}
		
		public function checkCollisions():void
		{
			// Collision with enemy
			if (collide('enemy', x, y))
			{
				SoundController.soundHit.play();
				if (inDarkness())
					y -= ENEMY_MOVE_DIST;
				else
					y += ENEMY_MOVE_DIST;
				//canMove = false;
				//stunAlarm.reset(STUN_TIME);
			}			
			
			// Collision with China (game over)
			if (collide('china', x, y))
			{
				GameWorld.gameOver = true;
			}		
		}
		
		public function checkSafeZone():void
		{
			if (distanceToPoint(FP.halfWidth, FP.halfHeight) < SafeZone.innerRadius && canMove)
			{
				Globals.timeAlive = GameWorld.timer.timePassed;
				Globals.modeOfDeath = 'absorbed';				
				SoundController.music.stop();
				SoundController.soundGlitch.play();
				canMove = false;
			}
			else if (distanceToPoint(FP.halfWidth, FP.halfHeight) > SafeZone.outerRadius)
			{
				Globals.timeAlive = GameWorld.timer.timePassed;
				Globals.modeOfDeath = 'destroyed';
				if (!China.shootingLazer)
				{
					China.shootLazer();
					//FP.world.remove(this);
					frozen = true;
				}
				canMove = false;
			}			
		}
		
		public function restoreMovement():void
		{
			canMove = true;
		}
		
		public function updateColor():void
		{
			//if (!canMove)
			//{
				//if (image.color != STUN_COLOR)
				//{
					//image.color = STUN_COLOR;
				//}
			//}
			if (distanceToPoint(FP.halfWidth, FP.halfHeight) > SafeZone.outerRadius)
			{
				if (color != Colors.WHITE)
				{
					color = Colors.WHITE;
				}				
			}
			else if (inDarkness())
			{
				if (color != Colors.WHITE)
				{
					color = Colors.WHITE;
				}
			}
			else if (color != Colors.BLACK)
			{
				color = Colors.BLACK;
			}
		}
		
		public function breatheIn():void
		{
			//trace('breathingIn');
			breathe = new NumTween(breatheOut);
			addTween(breathe);
			breathe.tween(1, 1.15, 1);
		}
		
		public function breatheOut():void
		{
			//trace('breathingOut');
			breathe = new NumTween(breatheIn);
			addTween(breathe);
			breathe.tween(1.15, 1, 1);			
		}		
		
		/**
		 * Checks whether the player is in darkness, based on position of LightTail.
		 * @return
		 */
		public function inDarkness():Boolean
		{
			if (distanceToPoint(FP.halfWidth, FP.halfHeight) < SafeZone.innerRadius)
				return true;
			else if (distanceToPoint(FP.halfWidth, FP.halfHeight) > SafeZone.outerRadius)
				return false;
			else if (LightTail.angle < 180)
				return true;
			else
				return false;
		}
		
		/**
		 * Applies gravity to the player.
		 */
		private function gravity():void
		{
			if (Math.abs(g) < GRAV)
			{
				if (g < 0) g -= 0.1;
				else g += 0.1;
			}
			// Reverse gravity depending on LightTail.
			if (inDarkness())
			{
				if (g < 0)
				{
					//speed = 0;
					g *= -1;
				}
			}
			else if (g > 0)
			{
				//speed = 0;
				g *= -1;
			}
			speed += g * FP.elapsed;
			if (speed > MAX_SPEED) 
				speed = MAX_SPEED;
			if (speed < -MAX_SPEED)
				speed = -MAX_SPEED;
		}
		
		/**
		 * Accelerates the player based on input.
		 */
		private function acceleration():void
		{
			accel = 0;
			// evaluate input
			//if (Math.abs(accel_current) < ACCEL)
			//{
				//if (accel_current < 0) accel_current -= 0.2;
				//else accel_current += 0.2;
			//}			
			if (accelCurrent < ACCEL)
				accelCurrent += 0.2;
			if (Input.check("RESIST") || Input.mouseDown) 
			{
				if (inDarkness())
					accel = -accelCurrent;
				else
					accel = accelCurrent;
			}
			  
			// Reverse gravity depending on LightTail.
			//if (inDarkness())
			//{
				//if (accel > 0)
				//{
					//speed = 0;
					//accel *= -1;
				//}
			//}
			//else if (accel < 0)
			//{
				//speed = 0;
				//accel *= -1;
			//}			
			
			// handle acceleration
			if (accel != 0)
			{
				speed += accel * FP.elapsed;
				if (speed > MAX_SPEED) 
					speed = MAX_SPEED;
				if (speed < -MAX_SPEED)
					speed = -MAX_SPEED;						
			}
	
			//if (accel != 0)
			//{
				// accelerate
				//if (speed < MAX_SPEED)
				//{
					//speed += accel * FP.elapsed;
					//if (speed > MAX_SPEED) speed = MAX_SPEED;
				//}
				//else accel = 0;
			//}
			
		}		
		
	}

}