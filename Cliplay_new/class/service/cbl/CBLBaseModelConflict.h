//
//  CBLBaseModelConflict.h
//  Cliplay
//
//  Created by 邢磊 on 2016/12/30.
//
//

#import "CBLBaseModel.h"

@interface CBLBaseModelConflict : CBLBaseModel
@property bool isFromLocal;
-(void)setInitialValue;
-(void)cleanEmptyChanges;
@end
