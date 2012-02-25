//
//  DMViewController.m
//  DiceMobile
//
//  Created by Leonhard Lichtschlag on 24/Feb/12.
//  Copyright (c) 2012 Leonhard Lichtschlag. All rights reserved.
//

#import "DMViewController.h"
#import "btBulletDynamicsCommon.h"


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    1.0f,-1.0f,-1.0f,			1.0f, 0.0f, 0.0f,
    1.0f, 1.0f,-1.0f,         1.0f, 0.0f, 0.0f,
    1.0f,-1.0f, 1.0f,         1.0f, 0.0f, 0.0f,
    1.0f,-1.0f, 1.0f,         1.0f, 0.0f, 0.0f,
    1.0f, 1.0f,-1.0f,         1.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 1.0f,         1.0f, 0.0f, 0.0f,
    
     1.0f, 1.0f,-1.0f,        0.0f, 1.0f, 0.0f,
    -1.0f, 1.0f,-1.0f,        0.0f, 1.0f, 0.0f,
     1.0f, 1.0f, 1.0f,        0.0f, 1.0f, 0.0f,
     1.0f, 1.0f, 1.0f,        0.0f, 1.0f, 0.0f,
    -1.0f, 1.0f,-1.0f,        0.0f, 1.0f, 0.0f,
    -1.0f, 1.0f, 1.0f,        0.0f, 1.0f, 0.0f,
    
    -1.0f, 1.0f,-1.0f,			-1.0f, 0.0f, 0.0f,
    -1.0f,-1.0f,-1.0f,			-1.0f, 0.0f, 0.0f,
    -1.0f, 1.0f, 1.0f,			-1.0f, 0.0f, 0.0f,
    -1.0f, 1.0f, 1.0f,			-1.0f, 0.0f, 0.0f,
    -1.0f,-1.0f,-1.0f,			-1.0f, 0.0f, 0.0f,
    -1.0f,-1.0f, 1.0f,			-1.0f, 0.0f, 0.0f,
    
    -1.0f, -1.0f,-1.0f,        0.0f, -1.0f, 0.0f,
     1.0f, -1.0f,-1.0f,        0.0f, -1.0f, 0.0f,
    -1.0f, -1.0f, 1.0f,        0.0f, -1.0f, 0.0f,
    -1.0f, -1.0f, 1.0f,        0.0f, -1.0f, 0.0f,
     1.0f, -1.0f,-1.0f,        0.0f, -1.0f, 0.0f,
     1.0f, -1.0f, 1.0f,        0.0f, -1.0f, 0.0f,
    
     1.0f, 1.0f, 1.0f,			0.0f, 0.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,			0.0f, 0.0f, 1.0f,
     1.0f,-1.0f, 1.0f,			0.0f, 0.0f, 1.0f,
     1.0f,-1.0f, 1.0f,			0.0f, 0.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,			0.0f, 0.0f, 1.0f,
    -1.0f,-1.0f, 1.0f,			0.0f, 0.0f, 1.0f,
    
	 1.0f,-1.0f, -1.0f,       0.0f, 0.0f, -1.0f,
	-1.0f,-1.0f, -1.0f,       0.0f, 0.0f, -1.0f,
	 1.0f, 1.0f, -1.0f,       0.0f, 0.0f, -1.0f,
	 1.0f, 1.0f, -1.0f,       0.0f, 0.0f, -1.0f,
	-1.0f,-1.0f, -1.0f,       0.0f, 0.0f, -1.0f,
	-1.0f, 1.0f, -1.0f,       0.0f, 0.0f, -1.0f
};


// ===============================================================================================================
@interface DMViewController () 
// ===============================================================================================================
{
	float _rotation;
	
	GLuint _vertexArray;
	GLuint _vertexBuffer;
	
	// Physics
	btDiscreteDynamicsWorld*				sDynamicsWorld;
	
	btBroadphaseInterface*					sBroadphase	;
	btCollisionConfiguration*				sCollisionConfig;
	btCollisionDispatcher*					sCollisionDispatcher;
	btSequentialImpulseConstraintSolver*	sConstraintSolver;
	
	btAlignedObjectArray<btRigidBody*>		sBoxBodies;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property int diceNumber;

- (void) setupGL;
- (void) setupScene;
- (void) setupBullet;

- (void) tearDownGL;
- (void) tearDownScene;
- (void) tearDownBullet;

@end


// ===============================================================================================================
@implementation DMViewController
// ===============================================================================================================

@synthesize context		= _context;
@synthesize effect			= _effect;
@synthesize diceNumber		= _diceNumber;


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark View Lifecycle
// ---------------------------------------------------------------------------------------------------------------

- (void) viewDidLoad
{
	[super viewDidLoad];

	self.diceNumber = 12;
	
	[self setupGL];
	[self setupBullet];
	[self setupScene];
}


- (void) viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    [self tearDownBullet];    
    [self tearDownScene];
}


- (void) setupGL
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) 
        NSLog(@"Failed to create GL ES 2.0 context");
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableMultisample = GLKViewDrawableMultisample4X;

	[EAGLContext setCurrentContext:self.context];
	glEnable(GL_DEPTH_TEST);
}


- (void) setupScene
{
	// load mesh for one dice
	[EAGLContext setCurrentContext:self.context];

	glGenVertexArraysOES(1, &_vertexArray);
	glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
	
	// create a simple effect for the dice
	self.effect = [[GLKBaseEffect alloc] init];
	self.effect.light0.enabled			= GL_TRUE;
	self.effect.light0.diffuseColor	= GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
	
	// -----------------------------------------------------------------------------------------------------------
	sDynamicsWorld->setGravity( btVector3(0, -10 ,0) );
	
	// create 6 planes / half spaces (world contraints)
	btBoxShape* worldBoxShape = new btBoxShape( btVector3(10, 10, 10) );	// world constraints
	for (int i = 0; i < 6; i++)
	{
		btVector4 planeEq;
		worldBoxShape->getPlaneEquation(planeEq, i);		// get the i-th side of world box
		btCollisionShape* worldBoxSideShape = new btStaticPlaneShape(-planeEq, planeEq[3]);
		
		btScalar mass = 0.0f;	// rigidbody is dynamic if and only if mass is non zero, otherwise static
		btVector3 localInertia(0, 0, 0);
		
		btTransform groundTransform;
		groundTransform.setIdentity();
		groundTransform.setOrigin( btVector3(0, 0, 0) );	// origin == translation
		
		btDefaultMotionState* myMotionState = new btDefaultMotionState(groundTransform);
		btRigidBody::btRigidBodyConstructionInfo rbInfo(mass, myMotionState, worldBoxSideShape, localInertia);
		
		btRigidBody* sFloorPlaneBody = new btRigidBody(rbInfo);
		
		// add the body to the dynamics world
		sDynamicsWorld->addRigidBody(sFloorPlaneBody);
	}
	
	// create the some boxes
	for (int i = 0; i < self.diceNumber; i++)
	{
		btCollisionShape* boxShape = new btBoxShape( btVector3(1, 1, 1) );
		
		btScalar mass = 1.0;		// positive mass means dynamic/moving object
		btVector3 localInertia(0, 0, 0);
		boxShape->calculateLocalInertia(mass, localInertia);
		
		btTransform objectTransform;
		objectTransform.setIdentity();
		float stride = 3.0;
		div_t division = div(i, 3);
		objectTransform.setOrigin( btVector3(division.rem * stride, division.quot * stride, 0) );

		btDefaultMotionState* myMotionState = new btDefaultMotionState(objectTransform);
		btRigidBody::btRigidBodyConstructionInfo rbInfo(mass, myMotionState, boxShape, localInertia);
		rbInfo.m_restitution	= 3;
		btRigidBody* boxBody	= new btRigidBody(rbInfo);
		
		sBoxBodies.push_back(boxBody);
		
		// most applications shouldn't disable deactivation, but for this demo it is better.
		boxBody->setActivationState(DISABLE_DEACTIVATION);
		// add the body to the dynamics world
		sDynamicsWorld->addRigidBody(boxBody);
	}
}


- (void) setupBullet
{
	// collision setup
	sCollisionConfig	= new btDefaultCollisionConfiguration();
	sBroadphase			= new btDbvtBroadphase();
	
	sCollisionDispatcher	= new btCollisionDispatcher(sCollisionConfig);
	sConstraintSolver		= new btSequentialImpulseConstraintSolver;
	sDynamicsWorld			= new btDiscreteDynamicsWorld(sCollisionDispatcher, sBroadphase, sConstraintSolver, sCollisionConfig);
}


- (void) tearDownGL
{
	if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;
}


- (void) tearDownScene
{
	// release buffers
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
	// release effects
    self.effect = nil;
	
	// TODO: release worldbox
	// TODO: release dice
}


- (void) tearDownBullet
{
	// Cleanup Bullet
	delete sDynamicsWorld;
	sDynamicsWorld			= NULL;
	
	delete sBroadphase;
	sBroadphase				= NULL;
	delete sCollisionConfig;
	sCollisionConfig		= NULL;
	delete sCollisionDispatcher;
	sCollisionDispatcher	= NULL;
	delete sConstraintSolver;
	sConstraintSolver		= NULL;
}



// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Interaction
// ---------------------------------------------------------------------------------------------------------------

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// ---------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Handling the frame loop
// ---------------------------------------------------------------------------------------------------------------

// Update the world state
- (void) update
{
	// compute projection matix
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f),	// FoV
															aspect,									// Sceen aspect
															0.1f, 100.0f);							// Near/far plane
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    	
	// move physics forward
	float frameRate = 1 / self.timeSinceLastUpdate;
	//	NSLog(@"%s %f %f %d", __PRETTY_FUNCTION__, frameRate, self.timeSinceLastUpdate, self.preferredFramesPerSecond);

	sDynamicsWorld->stepSimulation(frameRate, 2); // allow 2 steps if our graphics are lagging
	
	// for debugging: print the timing on the 10th frame
	static int i = 0;
	if (i < 10)
	{
		i++;
		if (i == 10)
			CProfileManager::dumpAll();
	}
}


// GLKViewDelegate method
- (void) glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	// draw background
	glPushGroupMarkerEXT(0, "Background");
	glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glPopGroupMarkerEXT();
    
	// draw the boxes for the dice with effect framework
	glPushGroupMarkerEXT(0, "Dice");
	glBindVertexArrayOES(_vertexArray);

	float worldMat[16];
	for (int i = 0; i < self.diceNumber; i++)
	{
		sBoxBodies[i]->getCenterOfMassTransform().getOpenGLMatrix(worldMat);
		GLKMatrix4 objectTransformMatrix = GLKMatrix4MakeWithArray(worldMat);
		
		GLKMatrix4 cameraTransformMatrix	= GLKMatrix4MakeTranslation(0.0f, 0.0f, -30.0f);
		self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(cameraTransformMatrix, objectTransformMatrix);
		
		[self.effect prepareToDraw];
		glDrawArrays(GL_TRIANGLES, 0, 36);
	}
	glPopGroupMarkerEXT();
}


@end
