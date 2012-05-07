//
//  MainView.h
//  Sparrow-Box2D
//
//  Created by Grzesiek Frydrych on 11-05-12.
//  Copyright 2011 Grzesiek Frydrych. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Box2D.h"
#import "GLES-Render.h"
#import "SPStage.h"


@interface MainView : SPStage <UIAccelerometerDelegate>
{
    b2World* world;
    GLESDebugDraw *m_debugDraw;
    NSMutableDictionary *_textures;
}

// adds a new sprite at a given coordinate
-(void) addNewSpriteWithCoords:(CGPoint)p;

@end
