//
//  CBLBaseModelConflict.m
//  Cliplay
//
//  Created by 邢磊 on 2016/12/30.
//
//

#import "CBLBaseModelConflict.h"

@implementation CBLBaseModelConflict
@dynamic isFromLocal;
- (void)awakeFromInitializer{
	[super awakeFromInitializer];
	if(self.isNew) {
		self.isFromLocal = YES;
		[self setInitialValue];
	}
}
-(void)setInitialValue {
	NSAssert(NO, @"Unimplemented setInitialValue method +[%@ docType]", [self class]);
}
-(void)cleanEmptyChanges {
	if(!self.isNew) {
		[self revertChanges];
	}
}
@end
