//
//  LHBall.m
//  SpaceConnon
//
//  Created by chenlihui on 14-5-5.
//  Copyright (c) 2014年 Future Game. All rights reserved.
//

#import "LHBall.h"

@implementation LHBall

-(void)updateTrail {
    if (self.trail) {
        self.trail.position = self.position;
    }
}

-(void)removeFromParent {
    if (self.trail) {
        self.trail.particleBirthRate = 0.0;
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime+ self.trail.particleLifetimeRange],[SKAction removeFromParent]]];
        [self runAction:removeTrail];
    }
    
    [super removeFromParent];
}


@end
