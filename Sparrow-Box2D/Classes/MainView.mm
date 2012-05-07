//
//  MainView.mm
//  Sparrow-Box2D
//
//  Created by Grzesiek Frydrych on 11-05-12.
//  Copyright 2011 Grzesiek Frydrych. All rights reserved.
//

#import "MainView.h"
#import "Sparrow.h"
#import "GB2ShapeCache.h"

//Pixel to meters ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32


@implementation MainView

// Create array of names of all textures
NSArray *_names= [NSArray arrayWithObjects:
                  @"hotdog",
                  @"drink",
                  @"icecream",
                  @"icecream2",
                  @"icecream3",
                  @"hamburger", 
                  @"orange",
                  nil];

- (id)initWithWidth:(float)width height:(float)height
{
    if ((self = [super initWithWidth:width height:height]))
    {
        // Enable accelerometer
        UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
        accelerometer.updateInterval = 1.0f/60.0f;
        accelerometer.delegate = self;
        
        // Enable Sparrow's listener of Touch Event
        [self addEventListener:@selector(onTouch:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
        
        // Init container of informations about loaded textures
        _textures = [[NSMutableDictionary alloc] init];
        
        // Load all textures now
        for (NSString *name in _names) {
            // Load texture
            SPTexture *texture = [[SPTexture alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", name]];
            
            // Store information about texture
            [_textures setObject:texture forKey:name];
            
            // Release texture object because we retained it in _textures
            [texture release];
        }
        
        // Load shapes from file created in PhysicsEditor
        [[GB2ShapeCache sharedShapeCache] addShapesWithFile:@"shapedefs.plist"];
        
        // Retrieve screen dimensions
        CGRect screenRect = [[UIScreen mainScreen] bounds];
		CGSize screenSize = CGSizeMake(screenRect.size.width, screenRect.size.height);
        
		// Define the gravity vector.
		b2Vec2 gravity;
		gravity.Set(0.0f, -10.0f);
		
		// Do we want to let bodies sleep?
		// This will speed up the physics simulation
		bool doSleep = true;
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		world = new b2World(gravity, doSleep);
		
		world->SetContinuousPhysics(true);
		
		// Debug Draw functions
		m_debugDraw = new GLESDebugDraw( PTM_RATIO );
        
        // Uncomment to enable Box2D debug draw
        //		world->SetDebugDraw(m_debugDraw);
		
        // We have to keep information about screen height because
        // Y-axis direction in Sparrow is reversed compared to Box2D
        // Sparrow (0,0) is top left corner
        // Box2D   (0,0) is bottom left corner
        m_debugDraw->_screenHeight = screenRect.size.height;
        
		uint32 flags = 0;
		flags += b2DebugDraw::e_shapeBit;
        //		flags += b2DebugDraw::e_jointBit;
        //		flags += b2DebugDraw::e_aabbBit;
        //		flags += b2DebugDraw::e_pairBit;
        //		flags += b2DebugDraw::e_centerOfMassBit;
		m_debugDraw->SetFlags(flags);		
		
		
		// Define the ground body.
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(0, 0); // bottom-left corner
		
		// Call the body factory which allocates memory for the ground body
		// from a pool and creates the ground box shape (also from a pool).
		// The body is also added to the world.
		b2Body* groundBody = world->CreateBody(&groundBodyDef);
		
		// Define the ground box shape.
		b2PolygonShape groundBox;		
		
		// bottom
		groundBox.SetAsEdge(b2Vec2(0,0), b2Vec2(screenSize.width/PTM_RATIO,0));
		groundBody->CreateFixture(&groundBox,0);
		
		// top
        groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO));
        groundBody->CreateFixture(&groundBox,0);
		
		// left
		groundBox.SetAsEdge(b2Vec2(0,screenSize.height/PTM_RATIO), b2Vec2(0,0));
		groundBody->CreateFixture(&groundBox,0);
		
		// right
		groundBox.SetAsEdge(b2Vec2(screenSize.width/PTM_RATIO,screenSize.height/PTM_RATIO), b2Vec2(screenSize.width/PTM_RATIO,0));
		groundBody->CreateFixture(&groundBox,0);
		
		
        // Set up sprite
        [self addNewSpriteWithCoords:CGPointMake(screenSize.width/2, screenSize.height/2)];
        
        // Add text field
        SPTextField *label = [SPTextField textFieldWithText:@"Tap screen to add or remove object"];
        label.width = 200;
        label.fontName = @"Marker Felt";
        label.fontSize = 32;
        label.color = SP_COLOR(0, 0, 255);
        label.x = screenSize.width/2 - label.width/2;
        label.y = 50;
        
        [self addChild:label atIndex:0];
    }
    
    return self;
}

// Scan all objects on the screen to determine whether any of them was touched
- (b2Body *)bodyTouchedAtPoint:(CGPoint)point
{
    // pixels -> meters
    point.x /= PTM_RATIO;
    point.y = (m_debugDraw->_screenHeight - point.y)/PTM_RATIO;
    
    // Each next object (body) in physics world
    for (b2Body *b = world->GetBodyList(); b; b = b->GetNext()) {
        // Ignore static objects (edges of the screen)
        if (b->GetType() != b2_staticBody) {
            // Each next fixture in body
            for (b2Fixture *f = b->GetFixtureList(); f; f = f->GetNext()) {
                // Any touch on fixture?
                if (f->TestPoint(b2Vec2(point.x, point.y))) {
                    // Yes, there was a touch so we return this object (body)
                    return b;
                }
            }
        }
    }
    
    // No object was touched
    return nil;
}

// Touch event will be handled here
- (void)onTouch:(SPTouchEvent*)event
{
    SPTouch *touch = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded] anyObject];
    if (touch) {
        CGPoint location = CGPointMake(touch.globalX, touch.globalY);
        
        if (b2Body *b = [self bodyTouchedAtPoint:location]) {
            // Object on the screen has been touched
            //   - delete Sparrow sprite from the screen
            //   - delete body from Box2D world
            [self removeChild:(SPSprite *)b->GetUserData()];
            world->DestroyBody(b);
        } else {
            // No object was touched
            //   - add new object on the screen
            [self addNewSpriteWithCoords: location];
        }
    }
}

-(void)render:(SPRenderSupport *)support
{
    // At first we have to draw Sparrow objects and then Box2D debug shapes.
    // This is because Sparrow clears the entire screen before drawing.
    // We will lost Box2D debug shapes if we draw them before Sparrow objects.
    [super render:support];
    
	// Needed states:  GL_VERTEX_ARRAY, 
	// Unneeded states: GL_TEXTURE_2D, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
    glEnableClientState(GL_VERTEX_ARRAY);
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
	world->DrawDebugData();
    
	// restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);    
    glDisableClientState(GL_VERTEX_ARRAY);
}

- (void)setAnchorPoint:(CGPoint)point forImage:(SPImage *)image
{
    // Anchor point coords are float values in range 0 - 1 thus we have to change them to pixel units
    point.x = image.width * point.x;
    
    // In PhysicsEditor point (0,0) is equal to bottom-left corner.
    // In Sparrow point (0,0) is equal to top-left corner.
    // We have to calculate Y-axis position a bit different than X-axis position
    point.y = image.height - (image.height * point.y);
    
    // Translate SPImage object to fit anchor point
    image.x = -point.x;
    image.y = -point.y;
}

-(void) addNewSpriteWithCoords:(CGPoint)p
{
	NSLog(@"Add sprite %0.2f x %02.f",p.x,p.y);
    
    // Random shape
    NSString *name = [_names objectAtIndex:rand()%[_names count]];
    
    // Sparrow v1.1 doesn't have anchor point support for SPImage.
    // No problem, we will use SPSprite object position as anchor point of SPImage object
    
    // Create SPSprite object
    SPSprite *sprite = [SPSprite sprite];
    
	// Set SPSprite object position to touch position
    sprite.x = p.x;
    sprite.y = p.y;
    
    // Create SPImage object
    SPImage *image = [SPImage imageWithTexture:[_textures objectForKey:name]];
    
    // Add SPImage as a child to SPSprite
    [sprite addChild:image];
    
    // Apply anchor point of selected shape to SPImage object
    [self setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:name]
                forImage:image];
    
    // Add SPSprite to this stage (SPStage)
	[self addChild:sprite];
    
    // Create physics body
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
    
    // Remember that Y-axis directions in Sparrow and Box2D are opposite
	bodyDef.position.Set(sprite.x/PTM_RATIO, (m_debugDraw->_screenHeight-sprite.y)/PTM_RATIO);
	bodyDef.userData = sprite;
	b2Body *body = world->CreateBody(&bodyDef);
    
    // Add the fixture definitions to the body
	[[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:name];
}

-(void)advanceTime:(double)seconds
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(seconds, velocityIterations, positionIterations);
    
	
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) 
		{
			SPSprite *myActor = (SPSprite*)b->GetUserData();
            myActor.x = b->GetPosition().x * PTM_RATIO;
            // Remember that Y-axis directions in Sparrow and Box2D are opposite
			myActor.y = m_debugDraw->_screenHeight - b->GetPosition().y * PTM_RATIO;
			myActor.rotation = -1 * b->GetAngle();
		}	
	}
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
    static float prevX=0, prevY=0;
    
    //#define kFilterFactor 0.05f
#define kFilterFactor 1.0f	// don't use filter. the code is here just as an example
    
    float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
    float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
    
    prevX = accelX;
    prevY = accelY;
    
    b2Vec2 gravity( accelX * 10, accelY * 10);
    
    world->SetGravity( gravity );
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
    [_textures release];
	delete world;
	world = NULL;
	
	delete m_debugDraw;
    
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
