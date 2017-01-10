//
//  Album.m
//  Cliplay
//
//  Created by 邢磊 on 2016/11/3.
//
//

#import "Album.h"

#define kAlbumDocType @"album"

@implementation Album

@dynamic title, desc, clips;

+ (NSString*) docType {
	return kAlbumDocType;
}

+ (NSString*) docID:(NSString *)uuid {
	return [NSString stringWithFormat:@"album_%@_%d", uuid, (int)[NSDate date].timeIntervalSinceReferenceDate];
}

+ (Album*) getAlbumInDatabase:(CBLDatabase*) database withTitle:(NSString *)title withUUID:(NSString *)uuid {	
	Album *album = (Album *)[super getModelInDatabase:database withUUID:uuid];
	album.title = title;
	album.desc = @"";
	return album;
}

-(void)setThumb: (UIImage*)image {
	[self setAttachmentNamed:kTaskImageName withContentType:ImageDataContentType content:[self dataForThumb:image]];
}

-(void)removeThumb {
	[self removeAttachmentNamed:kTaskImageName];
}

-(UIImage *)getThumb {
	NSArray *attachments = [self attachmentNames];
	if ([attachments count] > 0) {
		CBLAttachment *attachment = [self attachmentNamed:kTaskImageName];
		UIImage *attachedImage = [UIImage imageWithData:attachment.content];
		return attachedImage;
	} else {
		return nil;
	}
}

+(Class)clipsItemClass {
	return [ArticleEntity class];
}

//With image quality decreased
- (NSData *)dataForThumb:(UIImage *)image {
	return UIImageJPEGRepresentation(image, 0.1);
}

@end
