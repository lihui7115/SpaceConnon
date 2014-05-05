//
//  LHMyScene.m
//  SpaceConnon
//
//  Created by chenlihui on 14-5-2.
//  Copyright (c) 2014年 Future Game. All rights reserved.
//

#import "LHMyScene.h"
#import "LHMenu.h"
#import "LHBall.h"

static const CGFloat SHOOT_SPEED = 800.0;
static const CGFloat kHaloLowRadians = 200.0*M_PI/180;
static const CGFloat kHaloHighRadians = 340.0*M_PI/180;
static const CGFloat kHaloSpeed = 100.0;

static const uint32_t kEdgeCategory = 0x1 << 0;
static const uint32_t kBallCategory = 0x1 << 1;
static const uint32_t kHaloCategory = 0x1 << 2;
static const uint32_t kShieldCategory = 0x1 << 3;
static const uint32_t kLifebarCategory = 0x1 << 4;

static NSString * const kKeyTopScore = @"TopScore";
static NSString * const kSpawHaloKey = @"SpawHalo";


static inline CGVector radiansToVector(float radians) {
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high) {
    CGFloat value = arc4random_uniform(UINT32_MAX)/(CGFloat)UINT32_MAX;
    return value * (high-low) + low;
}

@interface LHMyScene () {
    SKNode *_mainLayer;
    LHMenu *_menu;
    BOOL _gameOver;
    
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKSpriteNode *_lifebar;
    SKLabelNode *_scoreLabel;
    BOOL _didShoot;
    
    SKAction *_bounce;
    SKAction *_deepExplosion;
    SKAction *_explosion;
    SKAction *_laser;
    SKAction *_zap;
    
    NSUserDefaults *_userDefault;
}

@end

@implementation LHMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        self.physicsWorld.contactDelegate = self;
        
        // add background
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        background.position = CGPointZero;
        background.anchorPoint = CGPointZero;
        background.blendMode = SKBlendModeReplace;
        [self addChild:background];
        
        // add edge
        SKNode *leftEdge = [SKNode node];
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, size.height + 100)];
        leftEdge.physicsBody.categoryBitMask = kEdgeCategory;
        leftEdge.position = CGPointZero;
        [self addChild:leftEdge];
        
        SKNode *rightEdge = [SKNode node];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, size.height + 100)];
        rightEdge.physicsBody.categoryBitMask = kEdgeCategory;
        rightEdge.position = CGPointMake(size.width, 0.0);
        [self addChild:rightEdge];
        
        // add gamelayer
        _mainLayer = [SKNode node];
        [self addChild:_mainLayer];
        
        // add connon
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        _cannon.position = CGPointMake(size.width*.5f, 0);
        _cannon.zRotation = M_PI/6;
        SKAction *action = [SKAction sequence:@[[SKAction rotateByAngle:M_PI-M_PI/3 duration:2],
                                                [SKAction rotateByAngle:-M_PI+M_PI/3 duration:2]]];
        [_cannon runAction:[SKAction repeatActionForever:action]];
        [self addChild:_cannon];
        
        // add halo
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:kSpawHaloKey];
        
        
        // add ammo
        
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        _ammoDisplay.anchorPoint = CGPointMake(.5, 0);
        _ammoDisplay.position = _cannon.position;
        [self addChild:_ammoDisplay];
        
        SKAction *increaseAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                      [SKAction runBlock:^{
            self.ammo++;
        }]]];
        
        [_ammoDisplay runAction:[SKAction repeatActionForever:increaseAmmo]];
        
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.position = CGPointMake(15, 10);
        _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _scoreLabel.fontSize = 15;
        [self addChild:_scoreLabel];
        
 
        _bounce = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
        _deepExplosion = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
        _explosion = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
        _laser = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
        _zap = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
        
        // setup menu
        _menu = [[LHMenu alloc]init];
        _menu.position = CGPointMake(size.width*.5, size.height-220);
        [self addChild:_menu];
        
        
//        [self newGame];
        
        // initial
        _gameOver = YES;
        self.score = 0;  // 这个初始化很重要 fix delay
        self.ammo = 5;
        _scoreLabel.hidden = YES;
        
        _userDefault = [NSUserDefaults standardUserDefaults];
        _menu.topScore = [_userDefault integerForKey:kKeyTopScore];
        
    }
    return self;
}


-(void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void)newGame {
    
    [self actionForKey:kSpawHaloKey].speed = 1.0;
    
    self.score = 0;
    self.ammo = 5;
    _scoreLabel.hidden = NO;
    
    _gameOver = NO;
    _menu.hidden = YES;
    
    [_mainLayer removeAllChildren];
    
    
    
    // add shield
    for (int i = 0; i < 6; ++i) {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.name = @"shield";
        shield.position = CGPointMake(35 + 50 *i, 90);
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = kShieldCategory;
        shield.physicsBody.collisionBitMask = 0;
        [_mainLayer addChild:shield];
    }
    
    // add lifebar
    _lifebar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    _lifebar.name = @"lifebar";
    _lifebar.position = CGPointMake(self.size.width*.5, 70);
    _lifebar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-self.size.width*.5, 0) toPoint:CGPointMake(self.size.width*.5, 0)];
    _lifebar.physicsBody.categoryBitMask = kLifebarCategory;
    [_mainLayer addChild:_lifebar];
}


-(void)gameOver {
    
    _menu.score = self.score;
    if (self.score > _menu.topScore) {
        _menu.topScore = self.score;
        
        [_userDefault setInteger:self.score forKey:kKeyTopScore];
        [_userDefault synchronize];
    }
    
    
    _scoreLabel.hidden = YES;
    _gameOver = YES;
    _menu.hidden = NO;
    
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    
//    [self performSelector:@selector(newGame) withObject:nil afterDelay:1.5];
}


-(void)spawnHalo {
    SKAction *spawHaloAction = [self actionForKey:kSpawHaloKey];
    if (spawHaloAction.speed < 1.5) {
        spawHaloAction.speed += 0.01;
    }
    
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width*.5, self.size.width-halo.size.width*.5), self.size.height+halo.size.height*.5);
    
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12];
    CGVector vector = radiansToVector(randomInRange(kHaloLowRadians, kHaloHighRadians));
    halo.physicsBody.velocity = CGVectorMake(vector.dx*kHaloSpeed, vector.dy*kHaloSpeed);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.categoryBitMask = kHaloCategory;
    halo.physicsBody.collisionBitMask = kEdgeCategory;  // 如果没有设置这个，halo跟halo之间也会发生碰撞的
    halo.physicsBody.contactTestBitMask = kBallCategory | kShieldCategory | kLifebarCategory | kEdgeCategory;
    
    [_mainLayer addChild:halo];
}

-(void)setAmmo:(int)ammo {
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}


-(void)shoot {
    if (self.ammo > 0) {
        self.ammo--;
        
        LHBall *ball = [LHBall spriteNodeWithImageNamed:@"Ball"];
        CGVector vector = radiansToVector(_cannon.zRotation);
        ball.position = CGPointMake(_cannon.position.x + _cannon.size.width*.5*vector.dx,
                                    _cannon.position.y + _cannon.size.height*.5*vector.dy);
        ball.name = @"ball";
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
        ball.physicsBody.velocity = CGVectorMake(vector.dx * SHOOT_SPEED, vector.dy * SHOOT_SPEED);
        //    ball.physicsBody.dynamic = NO;
        
        ball.physicsBody.restitution = 1.0;
        ball.physicsBody.friction = 0.0;
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.categoryBitMask = kBallCategory;
        ball.physicsBody.collisionBitMask = kEdgeCategory;  // 只跟edge起反应,没有的话，则ball穿不过shield
        ball.physicsBody.contactTestBitMask = kEdgeCategory;
        
        NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
        SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
        ballTrail.targetNode = _mainLayer;
        ball.trail = ballTrail;
        
        [_mainLayer addChild:ballTrail];
        [_mainLayer addChild:ball];
        [self runAction:_laser];


    }

}

-(void)addExplosion:(CGPoint)position withName:(NSString*)name {
    NSString *explosionPath = [[NSBundle mainBundle]pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
}


-(void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == kBallCategory && secondBody.categoryBitMask == kHaloCategory) {
        self.score++;
        [self addExplosion:secondBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosion];
        
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    if (firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kShieldCategory) {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosion];
        firstBody.categoryBitMask = 0;  // bug fix
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    if (firstBody.categoryBitMask == kHaloCategory && secondBody.categoryBitMask == kLifebarCategory) {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self addExplosion:secondBody.node.position withName:@"LifebarExplosion"];
        [self runAction:_deepExplosion];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    
    if (firstBody.categoryBitMask == kEdgeCategory && secondBody.categoryBitMask == kBallCategory) {
        [self addExplosion:contact.contactPoint withName:@"EdgeExplosion"];
        [self runAction:_bounce];

    }
    
    if (firstBody.categoryBitMask == kEdgeCategory && secondBody.categoryBitMask == kHaloCategory) {
//        [self addExplosion:contact.contactPoint withName:@"EdgeExplosion"];
        [self runAction:_zap];
        
    }

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        if (!_gameOver) {
            _didShoot = YES;
        }
        

    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (_gameOver) {
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if ([n.name isEqualToString:@"Play"]) {
                [self newGame];
            }
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void)didSimulatePhysics {
    if (_didShoot) {
//        SKAction *twoshot = [SKAction sequence:@[[SKAction runBlock:^{
//            [self shoot];
//        }],
//                                                 [SKAction waitForDuration:.5],
//                                                 [SKAction runBlock:^{
//            [self shoot];
//        }]]];

        [self shoot];
        _didShoot = NO;
    }
    
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0];
        }
        
        if (! CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
}

@end
