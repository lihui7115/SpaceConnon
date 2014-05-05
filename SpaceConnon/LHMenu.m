//
//  LHMenu.m
//  SpaceConnon
//
//  Created by chenlihui on 14-5-4.
//  Copyright (c) 2014年 Future Game. All rights reserved.
//

#import "LHMenu.h"

@implementation LHMenu
{
    SKLabelNode *_topScoreLabel;
    SKLabelNode *_scoreLabel;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.position = CGPointMake(0, 140);
        [self addChild:title];
        
        SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.position = CGPointMake(0, 70);
        [self addChild:scoreBoard];
        
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.name = @"Play";
        playButton.position = CGPointMake(0, 0);
        [self addChild:playButton];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.position = CGPointMake(-52, 50);
        [self addChild:_scoreLabel];
        
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.position = CGPointMake(48, 50);
        [self addChild:_topScoreLabel];
        
        self.topScore = 0;
        self.score = 0;
        
    }
    return self;
}

-(void)setTopScore:(int)topScore {
    _topScore = topScore;
    _topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];
}

-(void)setScore:(int)score {
    _score = score;
    _scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

@end
